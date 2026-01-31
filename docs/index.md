---
layout: default
title: Remote Coding from Coffee Shops - iPad Mini + Claude Code Setup
---

# Remote Coding from Coffee Shops: iPad Mini + Claude Code Setup

Ever wanted to take your development setup to a coffee shop without lugging around a laptop? I've built the perfect mobile coding workstation using an iPad Mini that connects to my Mac Studio at home running Claude Code. Here's how I did it.

## Why This Setup?

Working from coffee shops gives me a change of scenery and fresh energy, but I didn't want to compromise on my development environment. With this setup, I get:

- Full access to Claude Code running on my powerful Mac Studio
- A standing-height ergonomic workstation
- Voice input via Wispr Flow for faster interaction
- All the computing power at home, just the display and input devices with me

## The Shopping List

Here's everything you need to replicate this setup:

### Essential Tech

- **[Tailscale](https://tailscale.com)** - Free tier works perfectly for personal use. This creates a secure VPN connection between your devices.
- **[Terminus](https://termius.com)** - SSH client for iPad. The free version works, but premium adds nice features.
- **iPad Mini** - Any recent model works. The smaller size makes it perfect for portability.

### Hardware Setup

- **[TwelveSouth HoverBar Duo](https://www.amazon.com/dp/B08LDYG42M?tag=YOURAFFCODE)** - Adjustable iPad stand that works great for standing height. The dual arm design is sturdy and flexible.
- **[Apple Magic Keyboard](https://www.amazon.com/dp/B09BRFC6S5?tag=YOURAFFCODE)** - Compact, Bluetooth, and has great key travel. The rechargeable battery lasts weeks.
- **[Logitech MX Master Mouse](https://www.amazon.com/dp/B09HM94VDS?tag=YOURAFFCODE)** - Ergonomic, customizable buttons (crucial for the voice input trigger), and works on any surface.

### Voice Input (Optional but Highly Recommended)

- **[Cubilux Unidirectional USB-C Lavalier Microphone](https://www.amazon.com/dp/B0D1KZKX9J?tag=YOURAFFCODE)** - Clips to your shirt, connects directly to iPad Mini via USB-C, and provides excellent audio quality for [Wispr Flow](https://wispr.ai).

## Setup Guide

### Quick Setup Option

Want to automate the entire Mac setup? I've created a script that handles everything:

```bash
curl -fsSL https://raw.githubusercontent.com/nathangathright/ipad-remote-setup/main/setup.sh | bash
```

This script will:
- Install Tailscale with SSH support
- Configure tmux for persistent sessions
- Set up SSH keepalive for stable connections
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

**Important:** We're using the Homebrew CLI version because it supports Tailscale SSH server features like keyless authentication, ACLs, and session recording. The GUI apps from the App Store or standalone installer don't support running an SSH server through Tailscale.

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

Tailscale SSH provides keyless authentication using your Tailscale identity - no need to manage SSH keys, copy private keys to your iPad, or configure authorized_keys. It also supports ACLs and session recording for enhanced security.

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

MagicDNS automatically resolves your machine name, so no need to remember IP addresses. If your hostname doesn't resolve, you can use the full MagicDNS name shown in the Tailscale admin panel (e.g., `mac-studio.tail-scale.ts.net`).

**That's it!** Tailscale SSH handles authentication automatically through your Tailscale account - no keys to generate, copy, or manage.

### Part 2: The Physical Setup

#### 1. Assemble Your Standing Desk

1. Attach the **HoverBar Duo** to a table edge at comfortable standing height
2. Mount your iPad Mini in the HoverBar's grip
3. Place the **Magic Keyboard** on the table
4. Position the **MX Master Mouse** to your dominant side

The HoverBar's adjustable arms let you position the iPad at perfect eye level, reducing neck strain during long coding sessions.

#### 2. Configure Voice Input

**On your iPad:**

1. Install [Wispr Flow](https://apps.apple.com/us/app/whispr-flow/id1234567890) from the App Store
2. Connect the **Cubilux Lavalier Microphone** to your iPad's USB-C port
3. Clip the mic to your collar, about 6-8 inches from your mouth
4. Grant microphone permissions to Wispr Flow

**Configure MX Master Mouse button:**

1. Install [Logitech Options+](https://www.logitech.com/en-us/software/logi-options-plus.html) on your iPad
2. Customize one of the side buttons to trigger Wispr Flow recording
3. I use the forward thumb button - easy to tap while typing

### Part 3: Your Daily Workflow

Here's my typical coffee shop session:

1. **Arrive and set up** - Takes about 2 minutes to assemble everything
2. **Open Terminus** and connect to Mac Studio via Tailscale
3. **Run the coffee alias:**
   ```bash
   coffee
   ```
4. **Start coding** - Claude Code is exactly where you left it, or starts fresh if this is your first time
5. **Use voice input** - Hold the mouse button and speak prompts to Claude
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

### Optimizing for Coffee Shop WiFi

Tailscale handles network transitions seamlessly, but you can improve stability:

```bash
# On Mac Studio, increase SSH timeout
echo "ClientAliveInterval 60" | sudo tee -a /etc/ssh/sshd_config
echo "ClientAliveCountMax 3" | sudo tee -a /etc/ssh/sshd_config
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist
```

### Battery Life

The iPad Mini lasts 6-8 hours with this setup. The Magic Keyboard and MX Master both last weeks on a charge. Pack a small USB-C charger just in case.

### Security Considerations

- Tailscale encrypts all traffic end-to-end
- Your Mac Studio is only accessible via your private Tailscale network
- No ports are exposed to the public internet
- SSH provides an additional layer of authentication

## Total Cost Breakdown

| Item | Approximate Cost |
|------|-----------------|
| TwelveSouth HoverBar Duo | $80 |
| Apple Magic Keyboard | $99 |
| Logitech MX Master 3S | $100 |
| Cubilux USB-C Lavalier Mic | $30 |
| **Total Hardware** | **$309** |

Plus the iPad Mini you likely already own, and free software (Tailscale, Terminus free tier).

## Final Thoughts

This setup has transformed how I work. I get the portability of an iPad with the full power of my desktop development environment. The standing-height ergonomics keep me focused, and voice input makes interacting with Claude Code faster and more natural.

The initial setup takes about 30 minutes, but once configured, connecting from anywhere is seamless. Whether you're at a coffee shop, co-working space, or traveling, your full development environment is just a tap away.

The beauty of this setup is that it's not just for Claude Code - any terminal-based workflow benefits from this approach. You're essentially carrying a thin client to your powerful home machine.

## Questions?

Feel free to reach out if you run into any issues replicating this setup. The automated setup script and documentation are available at [github.com/nathangathright/ipad-remote-setup](https://github.com/nathangathright/ipad-remote-setup).

Happy remote coding!

---

*Disclosure: Some links in this post are affiliate links. If you purchase through them, I may earn a small commission at no extra cost to you. I only recommend products I personally use and believe in.*
