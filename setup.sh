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

# Install sesh (smart tmux session manager for Claude Code)
echo ""
echo "☕ Installing sesh..."
curl -fsSL https://raw.githubusercontent.com/nathangathright/sesh/main/install.sh | bash

# Add unlock function
SHELL_CONFIG=""
if [ -f ~/.zshrc ]; then
    SHELL_CONFIG=~/.zshrc
elif [ -f ~/.bashrc ]; then
    SHELL_CONFIG=~/.bashrc
elif [ -f ~/.bash_profile ]; then
    SHELL_CONFIG=~/.bash_profile
fi

if [ -n "$SHELL_CONFIG" ]; then
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

# Install tailserve skill for Claude Code
echo ""
echo "📚 Installing tailserve skill for Claude Code..."
TAILSERVE_DIR="$HOME/Developer/tailserve"

if [ ! -d "$TAILSERVE_DIR" ]; then
    git clone https://github.com/nathangathright/tailserve.git "$TAILSERVE_DIR"
else
    echo "  tailserve repo already present at $TAILSERVE_DIR"
fi

bash "$TAILSERVE_DIR/install.sh"
echo "✓ tailserve skill installed"

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
echo "4. Connect and run: sesh"
echo "5. Run 'unlock' if you need git or keychain access"
echo ""
echo "Shell functions:"
echo "  sesh                      # Smart: detects sessions, prompts when needed, resumes in tmux"
echo "  seshmyproject ~/code      # Create/attach 'myproject' session at ~/code"
echo "  sesh-s work -p ~/app      # Using named parameters"
echo "  unlock                   # Unlock macOS keychain over SSH"
echo ""
echo "To start using these commands:"
echo "  source $SHELL_CONFIG  # Load the new functions and aliases"
echo ""
echo "Happy remote coding! ☕"
