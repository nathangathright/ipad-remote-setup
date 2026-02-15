#!/bin/bash
# iPad Remote Coding Setup Script
# Sets up a Mac for remote access via Tailscale SSH and tmux

set -e  # Exit on error

echo "🚀 Setting up Mac for remote coding from iPad..."
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script is designed for macOS only"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✓ Homebrew already installed"
fi

# Install Tailscale
echo ""
echo "📡 Installing Tailscale CLI..."
if ! command -v tailscale &> /dev/null; then
    brew install tailscale
    echo "✓ Tailscale installed"
else
    echo "✓ Tailscale already installed"
fi

# Start Tailscale with SSH enabled
echo ""
echo "🔐 Checking Tailscale SSH..."
if ! tailscale status &> /dev/null; then
    echo "Please authenticate Tailscale in the browser window that opens..."
    sudo tailscale up --ssh
    echo "✓ Tailscale SSH enabled"
else
    # Check if SSH is already enabled
    SSH_ENABLED=$(tailscale debug prefs 2>/dev/null | grep -c '"RunSSH": true' || echo 0)
    if [ "$SSH_ENABLED" -eq 0 ]; then
        echo "Enabling SSH (requires sudo)..."
        sudo tailscale up --ssh
        echo "✓ Tailscale SSH enabled"
    else
        echo "✓ Tailscale SSH already enabled"
    fi
fi

# Get Tailscale hostname
# Extract the hostname for the current machine (first line with this machine's IP)
TAILSCALE_HOST=$(tailscale status --self=true | awk 'NR==1 {print $2}')
if [ -z "$TAILSCALE_HOST" ]; then
    # Fallback: strip .local from system hostname
    TAILSCALE_HOST=$(hostname | sed 's/\.local$//' | tr '[:upper:]' '[:lower:]')
fi

# Install tmux
echo ""
echo "🖥️  Installing and configuring tmux..."
if ! command -v tmux &> /dev/null; then
    brew install tmux
    echo "✓ tmux installed"
else
    echo "✓ tmux already installed"
fi

# Install qrencode for QR code generation
echo ""
echo "📱 Installing qrencode for QR code display..."
if ! command -v qrencode &> /dev/null; then
    brew install qrencode
    echo "✓ qrencode installed"
else
    echo "✓ qrencode already installed"
fi

# Create tmux config
echo ""
echo "📝 Creating tmux configuration..."
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

# Status bar styling
set -g status-style bg=black,fg=white
set -g status-right '#[fg=cyan]%Y-%m-%d %H:%M'
EOF
echo "✓ tmux configuration created"

# Add shell functions and aliases
echo ""
echo "☕ Adding shell functions and aliases..."
SHELL_CONFIG=""
if [ -f ~/.zshrc ]; then
    SHELL_CONFIG=~/.zshrc
elif [ -f ~/.bashrc ]; then
    SHELL_CONFIG=~/.bashrc
elif [ -f ~/.bash_profile ]; then
    SHELL_CONFIG=~/.bash_profile
fi

if [ -n "$SHELL_CONFIG" ]; then
    if ! grep -q "cc()" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Claude Code - Interactive menu helper (arrow keys + enter)" >> "$SHELL_CONFIG"
        cat >> "$SHELL_CONFIG" << 'FUNC'
_cc_select() {
  local prompt="$1"
  shift
  local -a options=("$@")
  local num_options=${#options[@]}
  local selected=0
  local key
  local ESC=$'\e'

  local saved_stty
  saved_stty=$(command stty -g 2>/dev/null)

  _cc_select_cleanup() {
    printf "${ESC}[?25h" >/dev/tty 2>/dev/null
    [[ -n "$saved_stty" ]] && command stty "$saved_stty" 2>/dev/null
  }

  trap '_cc_select_cleanup; return 1' INT TERM HUP

  printf "${ESC}[?25l" >/dev/tty
  command stty -echo raw 2>/dev/null

  _cc_select_draw() {
    local i
    [[ ${1:-0} -eq 1 ]] && printf "${ESC}[$((num_options + 2))A" >/dev/tty
    printf "${ESC}[2K\r${ESC}[1m%s${ESC}[0m\r\n" "$prompt" >/dev/tty
    for ((i = 0; i < num_options; i++)); do
      printf "${ESC}[2K\r" >/dev/tty
      if [[ $i -eq $selected ]]; then
        printf "  ${ESC}[7m${ESC}[1m > %s ${ESC}[0m" "${options[$((i + 1))]}" >/dev/tty
      else
        printf "  ${ESC}[2m   %s${ESC}[0m" "${options[$((i + 1))]}" >/dev/tty
      fi
      printf "\r\n" >/dev/tty
    done
    printf "${ESC}[2K\r${ESC}[2m  [↑/↓: navigate | enter: select | q: cancel]${ESC}[0m" >/dev/tty
  }

  _cc_select_draw 0

  while true; do
    read -r -k 1 key 2>/dev/null
    case "$key" in
      $'\r'|$'\n')
        printf "\r\n" >/dev/tty
        _cc_select_cleanup
        trap - INT TERM HUP
        SELECTED="${options[$((selected + 1))]}"
        return 0
        ;;
      q|Q)
        printf "\r\n" >/dev/tty
        _cc_select_cleanup
        trap - INT TERM HUP
        SELECTED=""
        return 1
        ;;
      "$ESC")
        local seq1="" seq2=""
        read -r -k 1 -t 0.1 seq1 2>/dev/null
        read -r -k 1 -t 0.1 seq2 2>/dev/null
        if [[ "$seq1" == "[" || "$seq1" == "O" ]]; then
          case "$seq2" in
            A) selected=$(( (selected - 1 + num_options) % num_options )) ;;
            B) selected=$(( (selected + 1) % num_options )) ;;
          esac
        elif [[ -z "$seq1" ]]; then
          printf "\r\n" >/dev/tty
          _cc_select_cleanup
          trap - INT TERM HUP
          SELECTED=""
          return 1
        fi
        ;;
      k) selected=$(( (selected - 1 + num_options) % num_options )) ;;
      j) selected=$(( (selected + 1) % num_options )) ;;
    esac
    _cc_select_draw 1
  done
}

FUNC
        echo "" >> "$SHELL_CONFIG"
        echo "# Claude Code - Smart tmux session manager" >> "$SHELL_CONFIG"
        cat >> "$SHELL_CONFIG" << 'FUNC'
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
      # Multiple sessions, let user choose with interactive menu
      local -a session_list=("${(@f)sessions}")
      if _cc_select "📋 Select a session:" "${session_list[@]}"; then
        session_name="$SELECTED"
        echo "🔗 Attaching to session: $session_name"
        tmux attach -t "$session_name"
        return
      else
        echo "❌ Cancelled"
        return 1
      fi
    else
      # No sessions exist - prompt for new session details
      local default_name=$(basename "$PWD")
      printf "📝 Session name [%s]: " "$default_name"
      read session_name
      if [ -z "$session_name" ]; then
        session_name="$default_name"
      fi

      local default_path="$PWD"
      printf "📂 Project path [%s]: " "$default_path"
      read project_path
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
    printf "📂 Project path [%s]: " "$default_path"
    read project_path
    if [ -z "$project_path" ]; then
      project_path="$default_path"
    fi
  fi

  # Expand ~ to home directory
  project_path="${project_path/#\~/$HOME}"

  # Check if directory exists
  if [ ! -d "$project_path" ]; then
    printf "❓ Directory '%s' does not exist. Create it? (y/n) " "$project_path"
    read REPLY
    if [[ $REPLY =~ ^[Yy] ]]; then
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
FUNC
        echo "✓ 'cc' function added to $SHELL_CONFIG"
    else
        echo "✓ 'cc' function already exists"
    fi

    if ! grep -q "unlock()" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Unlock macOS keychain (locked by default over SSH)" >> "$SHELL_CONFIG"
        cat >> "$SHELL_CONFIG" << 'FUNC'
unlock() {
  if security show-keychain-info ~/Library/Keychains/login.keychain-db 2>/dev/null; then
    echo "🔓 Keychain is already unlocked"
  else
    security unlock-keychain ~/Library/Keychains/login.keychain-db
  fi
}
FUNC
        echo "✓ 'unlock' function added to $SHELL_CONFIG"
    else
        echo "✓ 'unlock' function already exists"
    fi
fi

# Create initial tmux session (detached)
echo ""
echo "🎯 Creating initial Claude Code tmux session..."
if ! tmux has-session -t claude 2>/dev/null; then
    tmux new-session -s claude -d
    echo "✓ tmux session 'claude' created"
else
    echo "✓ tmux session 'claude' already exists"
fi

# Install Tailscale preview skill for Claude Code
echo ""
echo "📚 Installing Tailscale preview skill for Claude Code..."
SKILL_DIR="$HOME/.agents/skills/tailscale-preview"
SKILL_LINK="$HOME/.claude/skills/tailscale-preview"

# Create skill directory
mkdir -p "$SKILL_DIR"

# Create SKILL.md file
cat > "$SKILL_DIR/SKILL.md" << 'SKILLEOF'
---
name: tailscale-preview
description: Provides guidance on previewing web development projects over Tailscale, including framework-specific commands for binding to 0.0.0.0 and using Tailscale Funnel for public sharing.
---

# Tailscale Preview Guide

This skill provides Claude Code with the correct commands for previewing web projects over Tailscale across all frameworks.

## Core Concept

When running dev servers for preview over Tailscale, the server MUST bind to `0.0.0.0` (all interfaces) instead of `localhost` or `127.0.0.1`. Servers bound to localhost are only accessible from the same machine.

## Getting the Tailscale Hostname

```bash
# Get the current machine's Tailscale hostname
tailscale status --self | awk 'NR==1 {print $2}'
```

The preview URL will be: `http://<tailscale-hostname>:<port>`

## Framework-Specific Commands

### Vite (Vue, React, Svelte, etc.)

```bash
# Vite binds to localhost by default - must use --host flag
npm run dev -- --host 0.0.0.0
```

**Preview URL**: `http://<tailscale-hostname>:5173`

**Alternative**: Add to `vite.config.js/ts`:
```javascript
server: { host: '0.0.0.0' }
```

### Next.js

```bash
# Next.js 13+ defaults to 0.0.0.0, but explicitly set it to be sure
npm run dev -- -H 0.0.0.0
```

**Preview URL**: `http://<tailscale-hostname>:3000`

**Alternative**: Update `package.json`:
```json
"dev": "next dev -H 0.0.0.0"
```

### Create React App (CRA)

```bash
# Set HOST environment variable
HOST=0.0.0.0 npm start
```

**Preview URL**: `http://<tailscale-hostname>:3000`

**Alternative**: Add to `.env`:
```
HOST=0.0.0.0
```

### Cloudflare Workers (wrangler)

```bash
# Wrangler dev binds to localhost by default - use --ip flag
npx wrangler dev --ip 0.0.0.0
```

**Preview URL**: `http://<tailscale-hostname>:8787`

**Alternative**: Add to `wrangler.toml`:
```toml
[dev]
ip = "0.0.0.0"
```

### Astro

```bash
# Use --host flag
npm run dev -- --host 0.0.0.0
```

**Preview URL**: `http://<tailscale-hostname>:4321`

**Alternative**: Add to `astro.config.mjs`:
```javascript
server: { host: '0.0.0.0' }
```

### Python Flask

```python
# app.py
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Preview URL**: `http://<tailscale-hostname>:5000`

### Python Django

```bash
# Must specify 0.0.0.0 explicitly
python manage.py runserver 0.0.0.0:8000
```

**Preview URL**: `http://<tailscale-hostname>:8000`

### Node.js/Express

```javascript
// server.js
app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on 0.0.0.0:3000');
});
```

**Preview URL**: `http://<tailscale-hostname>:3000`

### Static File Servers

```bash
# Python http.server
python3 -m http.server 8000 --bind 0.0.0.0

# npx serve
npx serve -l 3000 --listen 0.0.0.0

# http-server
npx http-server -a 0.0.0.0 -p 8080
```

## Public Sharing with Tailscale Funnel

For sharing previews with people outside your Tailscale network:

```bash
# Make the dev server publicly accessible
tailscale funnel <port>

# Examples:
tailscale funnel 3000   # Next.js
tailscale funnel 5173   # Vite
tailscale funnel 8787   # Wrangler

# This creates a public URL: https://<hostname>.<tailnet>.ts.net
```

**Important**: The dev server still needs to bind to `0.0.0.0` for Funnel to work.

To stop funnel:
```bash
tailscale funnel --bg=false off
```

## Troubleshooting

### "Connection Refused" or "Can't Connect"

**Problem**: Server is binding to localhost instead of 0.0.0.0

**Solution**: Check the server startup logs. If you see:
- ❌ `http://localhost:3000` or `http://127.0.0.1:3000` → WRONG
- ✅ `http://0.0.0.0:3000` or shows network interfaces → CORRECT

Add the appropriate `--host` flag or config option for your framework.

### Firewall Issues

macOS may prompt to allow incoming connections the first time. Click "Allow".

### Wrong Hostname

If `tailscale status` shows an unexpected hostname, you can set a custom one:
```bash
sudo tailscale up --hostname=my-mac
```

## Quick Reference Table

| Framework | Command | Port |
|-----------|---------|------|
| Vite | `npm run dev -- --host 0.0.0.0` | 5173 |
| Next.js | `npm run dev -- -H 0.0.0.0` | 3000 |
| Wrangler | `npx wrangler dev --ip 0.0.0.0` | 8787 |
| Astro | `npm run dev -- --host 0.0.0.0` | 4321 |
| Django | `python manage.py runserver 0.0.0.0:8000` | 8000 |
| Flask | `app.run(host='0.0.0.0', port=5000)` | 5000 |

## Guidelines for Claude Code

When helping users preview web projects over Tailscale:

1. **Always** include the `--host 0.0.0.0` flag (or equivalent) in the dev server command
2. **Always** get the Tailscale hostname using `tailscale status --self`
3. **Always** provide the complete preview URL in the format `http://<tailscale-hostname>:<port>`
4. **Remind** them the dev server must bind to 0.0.0.0 for Tailscale access to work
5. **Suggest** Tailscale Funnel if they mention sharing with others outside their network

**Remember**: The most common mistake is forgetting to bind to 0.0.0.0!
SKILLEOF

# Create symlink
mkdir -p "$HOME/.claude/skills"
if [ ! -L "$SKILL_LINK" ]; then
    ln -s "$SKILL_DIR" "$SKILL_LINK"
    echo "✓ Tailscale preview skill installed"
else
    echo "✓ Tailscale preview skill already installed"
fi

# Build SSH URL for QR code
SSH_URL="ssh://$(whoami)@${TAILSCALE_HOST}"

# Display connection information
echo ""
echo "✅ Setup complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 iPad Connection Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Hostname: $TAILSCALE_HOST"
echo "Username: $(whoami)"
echo "Authentication: Tailscale SSH (automatic)"
echo ""

# Display QR code if qrencode is available
if command -v qrencode &> /dev/null; then
    echo "Scan this QR code from your iPad to open in Terminus:"
    echo ""
    qrencode -t UTF8 "$SSH_URL"
    echo ""
    echo "URL: $SSH_URL"
else
    echo "URL: $SSH_URL"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. On your iPad, install Tailscale and Terminus from the App Store"
echo "2. Sign into Tailscale with the same account"
echo "3. Scan the QR code above, or manually create a new host in Terminus:"
echo "   - Hostname: $TAILSCALE_HOST"
echo "   - Username: $(whoami)"
echo "   - Authentication: Default settings"
echo "4. Connect and run: coffee"
echo "5. Run 'unlock' if you need git or keychain access"
echo ""
echo "Shell functions:"
echo "  cc                       # Smart: detects sessions, prompts when needed, resumes in tmux"
echo "  cc myproject ~/code      # Create/attach 'myproject' session at ~/code"
echo "  cc -s work -p ~/app      # Using named parameters"
echo "  unlock                   # Unlock macOS keychain over SSH"
echo ""
echo "To start using these commands:"
echo "  source $SHELL_CONFIG  # Load the new functions and aliases"
echo ""
echo "Happy remote coding! ☕"
