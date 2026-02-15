# Remote Coding from Coffee Shops: iPad Mini + Claude Code Setup

Automated setup script for remote coding from an iPad using Tailscale SSH and tmux.

📖 **[Read the full guide with hardware recommendations](https://nathangathright.github.io/ipad-remote-setup/)**

## Quick Start

On your Mac (the one you want to access remotely):

```bash
curl -fsSL https://raw.githubusercontent.com/nathangathright/ipad-remote-setup/main/setup.sh | bash
```

On your iPad, install [Tailscale](https://apps.apple.com/us/app/tailscale/id1470499037) and [Terminus](https://apps.apple.com/us/app/termius-ssh-client/id549039908), then scan the QR code displayed by the script.

Connect and run `coffee` to start coding.

## What the Script Does

- Installs Tailscale (CLI version) with SSH support
- Installs tmux for persistent sessions with smooth scrolling
- Creates a smart `cc` function - the only command you need for Claude Code sessions
- Creates an `unlock` function to unlock the macOS keychain over SSH
- Installs a Claude Code skill that teaches it how to preview web projects over Tailscale
- Displays a QR code to configure Terminus on your iPad

## Manual Setup

If you prefer to set things up manually:

### 1. Tailscale

```bash
brew install tailscale
sudo tailscale up --ssh
```

> **Note:** Use the Homebrew CLI version. The App Store/GUI versions don't support Tailscale SSH server.

### 2. Tmux

```bash
brew install tmux

cat > ~/.tmux.conf << 'EOF'
# Enable mouse support
set -g mouse on

# Increase scrollback buffer
set -g history-limit 10000

# Better terminal type for modern terminals
set -g default-terminal "tmux-256color"

# Terminal overrides for better color and mouse support
set -ga terminal-overrides ",xterm-256color:Tc"
set -ga terminal-overrides ",*256col*:Tc"

# Fast escape time (better responsiveness)
set -sg escape-time 10

# Focus events for better terminal integration
set -g focus-events on
EOF

source ~/.zshrc
```

### 3. CC Function (The Only Command You Need)

Add the `cc` function - it handles everything based on context:

```bash
cat >> ~/.zshrc << 'EOF'
cc() {
  local session_name=""
  local project_path=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -s|--session)
        session_name="$2"
        shift 2
        ;;
      -p|--path)
        project_path="$2"
        shift 2
        ;;
      *)
        # Positional arguments: first is session, second is path
        if [ -z "$session_name" ]; then
          session_name="$1"
        elif [ -z "$project_path" ]; then
          project_path="$1"
        fi
        shift
        ;;
    esac
  done

  # Check if we're already inside a tmux session
  if [ -n "$TMUX" ]; then
    # We're inside tmux - resume/start Claude Code
    echo "🔄 Starting Claude Code..."
    claude --dangerously-skip-permissions --continue
    return
  fi

  # If no session name provided, check existing sessions
  if [ -z "$session_name" ]; then
    # Get list of existing sessions
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
    local session_count=0

    if [ -n "$sessions" ]; then
      session_count=$(echo "$sessions" | wc -l | tr -d ' ')
    fi

    if [ "$session_count" -eq 1 ]; then
      # Only one session, attach to it
      session_name=$(echo "$sessions" | head -1)
      echo "🔗 Attaching to session: $session_name"
      tmux attach -t "$session_name"
      return
    elif [ "$session_count" -gt 1 ]; then
      # Multiple sessions, let user choose
      echo "📋 Available sessions:"
      local i=1
      while IFS= read -r sess; do
        echo "  $i) $sess"
        i=$((i + 1))
      done <<< "$sessions"

      read -p "Select session (1-$session_count): " choice

      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$session_count" ]; then
        session_name=$(echo "$sessions" | sed -n "${choice}p")
        echo "🔗 Attaching to session: $session_name"
        tmux attach -t "$session_name"
        return
      else
        echo "❌ Invalid selection"
        return 1
      fi
    else
      # No sessions exist - prompt for new session details
      local default_name=$(basename "$PWD")
      read -p "📝 Session name [$default_name]: " session_name
      if [ -z "$session_name" ]; then
        session_name="$default_name"
      fi

      local default_path="$PWD"
      read -p "📂 Project path [$default_path]: " project_path
      if [ -z "$project_path" ]; then
        project_path="$default_path"
      fi
    fi
  fi

  # Check if session already exists (when session name was provided)
  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "🔗 Attaching to existing session: $session_name"
    tmux attach -t "$session_name"
    return
  fi

  # If no path provided yet, prompt for it
  if [ -z "$project_path" ]; then
    local default_path="$PWD"
    read -p "📂 Project path [$default_path]: " project_path
    if [ -z "$project_path" ]; then
      project_path="$default_path"
    fi
  fi

  # Expand ~ to home directory
  project_path="${project_path/#\~/$HOME}"

  # Check if directory exists
  if [ ! -d "$project_path" ]; then
    read -p "❓ Directory '$project_path' does not exist. Create it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      mkdir -p "$project_path"
      echo "✅ Created directory: $project_path"
    else
      echo "❌ Aborted."
      return 1
    fi
  fi

  # Create new session, navigate to path, and start Claude Code
  echo "✨ Creating new session '$session_name' at $project_path"
  tmux new-session -s "$session_name" -c "$project_path" -d
  tmux send-keys -t "$session_name" "claude --dangerously-skip-permissions" C-m
  tmux attach -t "$session_name"
}
EOF
source ~/.zshrc
```

**How it works:**
- **Inside tmux**: Resumes Claude Code
- **0 sessions**: Prompts for name (defaults to current dir) and path (defaults to current dir)
- **1 session**: Auto-attaches
- **Multiple sessions**: Shows selection menu
- **With arguments**: Creates/attaches to specified session

**Usage examples:**
```bash
cc                           # Context-aware - does the right thing
cc myproject ~/code          # Explicit session and path
cc -s work -p ~/app          # Named parameters
```

### 4. Keychain Unlock

macOS locks the login keychain over SSH, which blocks git credential helpers, code signing, and other tools. Add this function to your shell config:

```bash
cat >> ~/.zshrc << 'EOF'
unlock() {
  if security show-keychain-info ~/Library/Keychains/login.keychain-db 2>/dev/null; then
    echo "🔓 Keychain is already unlocked"
  else
    security unlock-keychain ~/Library/Keychains/login.keychain-db
  fi
}
EOF
source ~/.zshrc
```

Run `unlock` after connecting to enter your password and restore keychain access.

### 5. iPad

Install Tailscale (same account) and Terminus. Create a host using your Mac's Tailscale hostname and username.

## Previewing Web Projects

Since your iPad and Mac are on the same Tailscale network, any dev server running on your Mac is already accessible from your iPad — just visit `http://<tailscale-hostname>:<port>` in Safari. Make sure your dev server binds to `0.0.0.0` instead of `localhost` (most frameworks have a `--host` flag for this).

The setup script installs a **Tailscale Preview skill** that teaches Claude Code the correct commands for every framework (Vite, Next.js, Wrangler, etc.). Just ask Claude to "preview this project over Tailscale" and it will know what to do!

**Manual reference**: See [CLAUDE.md](CLAUDE.md) for detailed framework-specific commands and troubleshooting tips.

To share a preview with someone outside your Tailscale network, use [Tailscale Funnel](https://tailscale.com/kb/1223/funnel):

```bash
tailscale funnel 3000
```

This gives you a public `https://<hostname>.<tailnet>.ts.net` URL with no extra tools or accounts required.

## Uninstalling

```bash
brew uninstall tailscale tmux qrencode
rm ~/.tmux.conf
rm -rf ~/.agents/skills/tailscale-preview
rm ~/.claude/skills/tailscale-preview
# Remove the cc function and unlock function from ~/.zshrc
```

## License

MIT
