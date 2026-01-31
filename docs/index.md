---
layout: default
title: Remote Coding from Coffee Shops - iPad Mini + Claude Code Setup
---

Ever wanted to take your development setup to a coffee shop without lugging around a laptop? I've built the perfect mobile coding workstation using an iPad Mini that connects to my Mac Studio at home running Claude Code. Here's how I did it.

## Why This Setup?

Working from coffee shops gives me a change of scenery and fresh energy, but I didn't want to compromise on my development environment. With this setup, I get:

- Full access to Claude Code running on my powerful Mac Studio
- A standing-height ergonomic workstation
- Voice input via Wispr Flow for faster interaction
- All the computing power at home, just the display and input devices with me

## The Shopping List

Here's everything you need to replicate this setup:

### Software
- **[Claude Code](https://claude.ai/code)** - Anthropic's agentic coding tool that lives in your terminal.
- **[Tmux](https://github.com/tmux/tmux)** - Terminal multiplexer that keeps sessions alive when you disconnect.
- **[Tailscale](https://tailscale.com)** - Free tier works perfectly for personal use. Creates a secure VPN connection between your devices.
- **[Terminus](https://termius.com)** - SSH client for iPad. The free version works, but premium adds nice features.
- **[Wispr Flow](https://wispr.ai)** - Voice-to-text app that acts as a keyboard, typing out your speech wherever the cursor is focused.

### Hardware

- **[Mac Studio](https://www.amazon.com/dp/B0FNS1ZX5B?tag=nathangathright-20)** - The always-on powerhouse at home running Claude Code. Any Mac works, but desktop machines handle the "always available" role best.
- **[iPad Mini](https://www.amazon.com/dp/B0DKL4DTYN?tag=nathangathright-20)** - Any recent model works. The smaller size makes it perfect for portability.
- **[TwelveSouth HoverBar Duo](https://www.amazon.com/dp/B0B6QD3NZV?tag=nathangathright-20)** - Adjustable iPad stand that works great for standing height ergonomics.
- **[Apple Magic Keyboard](https://www.amazon.com/dp/B0DL6LV7Q6?tag=nathangathright-20)** - Compact, Bluetooth, and has great key travel. The rechargeable battery lasts weeks.
- **[Logitech MX Master 4 Wireless Mouse](https://www.amazon.com/dp/B0FC5V3YVY?tag=nathangathright-20)** - Ergonomic, works on any surface, and pairs easily with iPad via Bluetooth.
- **[Cubilux Unidirectional USB-C Lavalier Microphone](https://www.amazon.com/dp/B0963DLZCH?tag=nathangathright-20)** - Clips to your shirt, connects directly to iPad Mini via USB-C, and provides excellent isolation for noisy environments.

## Setup Guide

### Quick Setup Option

Want to automate the entire Mac setup? I've created a script that handles everything:

```bash
curl -fsSL https://raw.githubusercontent.com/nathangathright/ipad-remote-setup/main/setup.sh | bash
```

This script will:
- Install Tailscale with SSH support
- Configure tmux for persistent sessions
- Add the `coffee` alias to your shell
- Display your connection details for iPad setup

If you prefer to understand each step or customize the setup, follow the manual instructions below. Otherwise, skip to [Part 2: The Physical Setup](#part-2-the-physical-setup).

### Part 1: Establishing Remote Access (Manual Setup)

#### 1. Install Tailscale

First, we need to create a secure tunnel between your devices.

**On your Mac Studio (at home):**

```bash
# Install Tailscale CLI version (required for SSH server features)
brew install tailscale

# Start Tailscale and authenticate
sudo tailscale up
```

> [!IMPORTANT]
> We're using the Homebrew CLI version because it supports keyless SSH authentication. The GUI apps from the App Store or standalone installer don't support running an SSH server through Tailscale.

**On your iPad:**

1. Install Tailscale from the App Store
2. Sign in with the same account
3. Both devices should now appear in your Tailscale admin panel

**Enable SSH on your Mac Studio:**

```bash
# Enable Tailscale SSH with keyless authentication
sudo tailscale up --ssh

# Verify Tailscale is running and check your machine name
tailscale status
```

Tailscale SSH provides keyless authentication using your Tailscale identity—no need to manage SSH keys, copy private keys to your iPad, or configure authorized_keys.

Tailscale's MagicDNS is enabled by default and provides a friendly hostname for your Mac. You'll see your machine name in the output (e.g., `mac-studio`). You can connect using just the machine name instead of memorizing IP addresses.

#### 2. Set Up Tmux for Persistent Sessions

Tmux keeps your Claude Code session running even when you disconnect.

**On your Mac Studio:**

```bash
# Install tmux
brew install tmux

# Create a basic tmux config (optional but recommended)
cat > ~/.tmux.conf << 'EOF'
# Enable mouse support
set -g mouse on

# Increase scrollback buffer
set -g history-limit 10000

# Better colors
set -g default-terminal "screen-256color"
EOF

# Add a convenient alias for connecting
echo "alias coffee='tmux attach -t claude || tmux new-session -s claude claude'" >> ~/.zshrc
source ~/.zshrc
```

**Start your first session:**

```bash
# Create a session named 'claude'
tmux new-session -s claude

# Inside tmux, start Claude Code
claude

# Detach from tmux (but leave it running): Ctrl+B, then D
```

The `coffee` alias makes your daily workflow simpler - it automatically attaches to your existing Claude session or creates a new one if it doesn't exist.

#### 3. Configure Terminus on iPad

1. Install Terminus from the App Store
2. Add a new host:
   - **Label:** Mac Studio
   - **Hostname:** Your Mac's Tailscale hostname (e.g., `mac-studio` or the machine name you saw in `tailscale status`)
   - **Username:** Your Mac username
   - **Authentication:** Leave default settings

If your hostname doesn't resolve, you can use the full MagicDNS name shown in the Tailscale admin panel (e.g., `mac-studio.tail-scale.ts.net`).

**That's it!** Tailscale SSH handles authentication automatically—no additional configuration needed in Terminus.

### Part 2: The Physical Setup

Set up the HoverBar Duo at standing height and mount your iPad. The adjustable arms let you position it at eye level, reducing neck strain. Pair your keyboard and mouse via Bluetooth, and if you're using voice input, plug the lavalier mic into your iPad's USB-C port.

### Part 3: Your Daily Workflow

Here's my typical coffee shop session:

1. **Arrive and set up** - Takes about 2 minutes to assemble everything
2. **Open Terminus** and connect to Mac Studio via Tailscale
3. **Run the coffee alias:**
   ```bash
   coffee
   ```
4. **Start coding** - Claude Code is exactly where you left it, or starts fresh if this is your first time
5. **Use voice input** - Tap to activate Wispr Flow and speak prompts to Claude
6. **Detach when leaving:**
   ```bash
   # Press Ctrl+B, then D to detach
   # Or just close Terminus - tmux keeps running
   ```

Everything stays running at home, so you can pick up where you left off from any location. The `coffee` alias handles all the tmux session management automatically.

## Tips and Tricks

### Tmux Quick Reference

- **List sessions:** `tmux ls`
- **Create new session:** `tmux new -s [name]`
- **Attach to session:** `tmux attach -t [name]`
- **Detach:** `Ctrl+B`, then `D`
- **Kill session:** `tmux kill-session -t [name]`

### Security Considerations

- Tailscale encrypts all traffic end-to-end
- Your Mac Studio is only accessible via your private Tailscale network
- No ports are exposed to the public internet
- SSH provides an additional layer of authentication

## Final Thoughts

This setup has transformed how I work. I get the portability of an iPad with the full power of my desktop development environment. The standing-height ergonomics keep me focused, and voice input makes interacting with Claude Code faster and more natural.

The initial setup takes about 30 minutes, but once configured, connecting from anywhere is seamless. Whether you're at a coffee shop, co-working space, or traveling, your full development environment is just a tap away.

The beauty of this setup is that it's not just for Claude Code - any terminal-based workflow benefits from this approach. You're essentially carrying a thin client to your powerful home machine.

## Questions?

Feel free to reach out if you run into any issues replicating this setup. The automated setup script and documentation are available at [github.com/nathangathright/ipad-remote-setup](https://github.com/nathangathright/ipad-remote-setup).

Happy remote coding!

---

*Disclosure: Some links in this post are affiliate links. If you purchase through them, I may earn a small commission at no extra cost to you. I only recommend products I personally use and believe in.*
