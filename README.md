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
- Creates a `coffee` alias that attaches to your Claude Code session
- Creates `cc-start` and `cc-continue` aliases for Claude Code
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

echo "alias coffee='tmux attach -t claude || tmux new-session -s claude claude'" >> ~/.zshrc
echo "alias cc-start='claude --dangerously-skip-permissions'" >> ~/.zshrc
echo "alias cc-continue='claude --dangerously-skip-permissions --continue'" >> ~/.zshrc
source ~/.zshrc
```

### 3. Keychain Unlock

macOS locks the login keychain over SSH, which blocks git credential helpers, code signing, and other tools. Add this function to your shell config:

```bash
cat >> ~/.zshrc << 'EOF'
unlock() {
  if security show-keychain-info ~/Library/Keychains/login.keychain-db 2>/dev/null; then
    echo "Keychain is already unlocked"
  else
    security unlock-keychain ~/Library/Keychains/login.keychain-db
  fi
}
EOF
source ~/.zshrc
```

Run `unlock` after connecting to enter your password and restore keychain access.

### 4. iPad

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
# Remove the coffee, cc-start, cc-continue aliases and unlock function from ~/.zshrc
```

## License

MIT
