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
- Creates a smart `coffee` function for managing tmux sessions and projects
- Creates `cc-danger` and `cc-resume` aliases for Claude Code
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

echo "alias cc-danger='claude --dangerously-skip-permissions'" >> ~/.zshrc
echo "alias cc-resume='claude --dangerously-skip-permissions --continue'" >> ~/.zshrc
source ~/.zshrc
```

### 3. Coffee Function (Smart Session Manager)

Add the `coffee` function for managing tmux sessions:

```bash
cat >> ~/.zshrc << 'EOF'
coffee() {
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

  # Default session name if not provided
  if [ -z "$session_name" ]; then
    session_name="claude"
  fi

  # Check if session already exists
  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "☕ Attaching to existing session: $session_name"
    tmux attach -t "$session_name"
    return
  fi

  # Session doesn't exist, need a path
  if [ -z "$project_path" ]; then
    read -p "📂 Enter project path: " project_path
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
  echo "☕ Creating new session '$session_name' at $project_path"
  tmux new-session -s "$session_name" -c "$project_path" -d
  tmux send-keys -t "$session_name" "claude --dangerously-skip-permissions" C-m
  tmux attach -t "$session_name"
}
EOF
source ~/.zshrc
```

**Usage examples:**
```bash
coffee                              # Default 'claude' session (prompts for path)
coffee myproject ~/Developer/myapp  # Create/attach 'myproject' at ~/Developer/myapp
coffee -s work -p ~/code            # Named parameters
coffee myproject                    # Attach if exists, or prompt for path
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
# Remove the coffee function, cc-danger, cc-resume aliases, and unlock function from ~/.zshrc
```

## License

MIT
