# Remote Coding from Coffee Shops: iPad Mini + Claude Code Setup

Automated setup script for remote coding from an iPad using Tailscale SSH and tmux.

📖 **[Read the full guide with hardware recommendations](https://nathangathright.github.io/ipad-remote-setup/)**

## Quick Start

On your Mac (the one you want to access remotely):

```bash
curl -fsSL https://raw.githubusercontent.com/nathangathright/ipad-remote-setup/main/setup.sh | bash
```

On your iPad, install [Tailscale](https://apps.apple.com/us/app/tailscale/id1470499037) and [Terminus](https://apps.apple.com/us/app/termius-ssh-client/id549039908), then scan the QR code displayed by the script.

Connect and run `sesh` to start coding.

## What the Script Does

- Installs Tailscale (CLI version) with SSH support
- Installs tmux for persistent sessions with smooth scrolling
- Creates a smart `sesh` function - the only command you need for Claude Code sessions
- Creates an `unlock` function to unlock the macOS keychain over SSH
- Installs the [tailserve](https://github.com/nathangathright/tailserve) skill that teaches Claude Code how to preview web projects over Tailscale
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

### 3. sesh (The Only Command You Need)

Install [sesh](https://github.com/nathangathright/sesh), a smart tmux session manager for Claude Code:

```bash
curl -fsSL https://raw.githubusercontent.com/nathangathright/sesh/main/install.sh | bash
source ~/.zshrc
```

See the [sesh repo](https://github.com/nathangathright/sesh) for full usage details.

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

Since your iPad and Mac are on the same Tailscale network, any dev server running on your Mac is already accessible from your iPad. The setup script installs the [tailserve](https://github.com/nathangathright/tailserve) skill that teaches Claude Code the correct commands for every framework (Vite, Next.js, Wrangler, etc.). Just ask Claude to "preview this project over Tailscale" and it will know what to do.

tailserve covers three approaches:
- **Direct tailnet access** — bind to `0.0.0.0`, access via `http://<hostname>:<port>`
- **`tailscale serve`** — automatic HTTPS, path-based routing for multiple projects
- **`tailscale funnel`** — public sharing via the internet

## Uninstalling

```bash
brew uninstall tailscale tmux qrencode
rm ~/.tmux.conf
rm ~/.claude/skills/tailserve
rm ~/.agents/skills/tailserve
rm -rf ~/Developer/tailserve
# Remove the sesh function and unlock function from ~/.zshrc
```

## License

MIT
