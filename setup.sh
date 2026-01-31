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
echo "🔐 Enabling Tailscale SSH..."
if ! tailscale status &> /dev/null; then
    echo "Please authenticate Tailscale in the browser window that opens..."
    sudo tailscale up --ssh
else
    # Update to enable SSH if not already enabled
    sudo tailscale up --ssh
    echo "✓ Tailscale SSH enabled"
fi

# Get Tailscale hostname
TAILSCALE_HOST=$(tailscale status | grep "$(hostname)" | awk '{print $2}' | head -1)
if [ -z "$TAILSCALE_HOST" ]; then
    TAILSCALE_HOST=$(hostname)
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

# Better colors
set -g default-terminal "screen-256color"

# Status bar styling
set -g status-style bg=black,fg=white
set -g status-right '#[fg=cyan]%Y-%m-%d %H:%M'
EOF
echo "✓ tmux configuration created"

# Add coffee alias to shell config
echo ""
echo "☕ Adding 'coffee' alias to shell..."
SHELL_CONFIG=""
if [ -f ~/.zshrc ]; then
    SHELL_CONFIG=~/.zshrc
elif [ -f ~/.bashrc ]; then
    SHELL_CONFIG=~/.bashrc
elif [ -f ~/.bash_profile ]; then
    SHELL_CONFIG=~/.bash_profile
fi

if [ -n "$SHELL_CONFIG" ]; then
    if ! grep -q "alias coffee=" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# iPad Remote Coding - Quick tmux attachment" >> "$SHELL_CONFIG"
        echo "alias coffee='tmux attach -t claude || tmux new-session -s claude claude'" >> "$SHELL_CONFIG"
        echo "✓ 'coffee' alias added to $SHELL_CONFIG"
    else
        echo "✓ 'coffee' alias already exists"
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
echo ""
echo "To start Claude Code locally:"
echo "  source $SHELL_CONFIG  # Load the new alias"
echo "  coffee                # Connect to tmux session"
echo ""
echo "Happy remote coding! ☕"
