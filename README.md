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
- Installs tmux for persistent sessions
- Creates a `coffee` alias that attaches to your Claude Code session
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
set -g mouse on
set -g history-limit 10000
set -g default-terminal "screen-256color"
EOF

echo "alias coffee='tmux attach -t claude || tmux new-session -s claude claude'" >> ~/.zshrc
source ~/.zshrc
```

### 3. iPad

Install Tailscale (same account) and Terminus. Create a host using your Mac's Tailscale hostname and username.

## Uninstalling

```bash
brew uninstall tailscale tmux qrencode
rm ~/.tmux.conf
# Remove the coffee alias from ~/.zshrc
```

## License

MIT
