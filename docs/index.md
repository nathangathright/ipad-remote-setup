---
layout: default
title: Remote Coding from Coffee Shops - iPad Mini + Claude Code Setup
---

I wanted to code from coffee shops without lugging a laptop. So I built a mobile workstation: an iPad Mini that connects to my Mac Studio at home running Claude Code. All the computing power stays home. I just carry the display, keyboard, and mouse.

This is my setup. There are many[^1] like[^2] it[^3], but this one is mine.

## The Shopping List

- **[Mac Studio](https://www.amazon.com/dp/B0FNS1ZX5B?tag=nathangathright-20)** - The always-on powerhouse at home running Claude Code. Any Mac works, but desktop machines handle the "always available" role best.
- **[iPad Mini](https://www.amazon.com/dp/B0DKL4DTYN?tag=nathangathright-20)** - Any recent model works. The smaller size makes it perfect for portability.
- **[TwelveSouth HoverBar Duo](https://www.amazon.com/dp/B0B6QD3NZV?tag=nathangathright-20)** - Adjustable iPad stand that works great for standing height ergonomics.
- **[Apple Magic Keyboard](https://www.amazon.com/dp/B0DL6LV7Q6?tag=nathangathright-20)** - Compact, Bluetooth, and has great key travel. The rechargeable battery lasts weeks.
- **[Logitech MX Master 4 Wireless Mouse](https://www.amazon.com/dp/B0FC5V3YVY?tag=nathangathright-20)** - Ergonomic, works on any surface, and pairs easily with iPad via Bluetooth.
- **[Cubilux Unidirectional USB-C Lavalier Microphone](https://www.amazon.com/dp/B0963DLZCH?tag=nathangathright-20)** - Clips to your shirt, connects directly to iPad Mini via USB-C, and provides excellent isolation for noisy environments.

## Setup Guide

### Configure Your Mac

Run the setup script on your Mac (the one you want to access remotely):

```bash
curl -fsSL https://raw.githubusercontent.com/nathangathright/ipad-remote-setup/main/setup.sh | bash
```

This installs Tailscale and tmux, configures everything for remote access, and displays a QR code for easy iPad setup. It also adds powerful shell helpers:

- **`cc`** - The only command you need! Context-aware session manager (resumes in tmux, auto-attaches to single session, shows menu for multiple, prompts for new)
- **`unlock`** - Unlocks the macOS keychain (locked by default over SSH)

The script also installs a **Claude Code skill** that teaches it how to properly preview web projects over Tailscale for any framework—so Claude always knows to bind servers to `0.0.0.0` instead of localhost.

Tailscale encrypts all traffic end-to-end and your Mac is only accessible to devices on your private network—no ports exposed to the internet.

If you prefer to set things up manually, see the [README](https://github.com/nathangathright/ipad-remote-setup) for step-by-step instructions.

### Configure Your iPad

Install these apps from the App Store:
- [Tailscale](https://apps.apple.com/us/app/tailscale/id1470499037) - Sign in with the same account you used on your Mac
- [Terminus](https://apps.apple.com/us/app/termius-ssh-client/id549039908) - The SSH client you'll use to connect
- [Wispr Flow](https://apps.apple.com/app/id6497229487) - For voice input (optional)

Then scan the QR code displayed by the setup script from your iPad's camera. This opens Terminus with your connection pre-filled.

If the QR code doesn't work, manually create a new host in Terminus using the hostname and username shown by the script.

## Your Daily Workflow

Here's my typical coffee shop session:

1. **Arrive and set up** - Takes about 2 minutes to assemble everything
2. **Open Terminus** and connect to Mac Studio via Tailscale
3. **Unlock the keychain** if you need git or code signing:
   ```bash
   unlock
   ```
4. **Start coding - just type `cc`:**
   ```bash
   # The cc command does the right thing based on context:

   # Inside tmux? Resumes Claude Code
   cc

   # No sessions? Prompts for name and path (smart defaults)
   cc
   # 📝 Session name [myapp]: ↵
   # 📂 Project path [/Users/you/myapp]: ↵

   # One session? Auto-attaches
   cc

   # Multiple sessions? Shows menu
   cc
   # 📋 Available sessions:
   #   1) work
   #   2) side-project
   #   3) claude

   # Or be explicit
   cc myproject ~/code
   cc -s work -p ~/app
   ```
5. **Code away** - Claude Code launches automatically. The `cc` function handles everything: session management, directory navigation, and starting Claude Code.
6. **Use voice input** - Tap to activate Wispr Flow and speak prompts to Claude
7. **Detach when leaving:**
   ```bash
   # Press Ctrl+B, then D to detach
   # Or just close Terminus - tmux keeps running
   ```

Everything stays running at home, so you can pick up where you left off from any location. You can have multiple named sessions for different projects.

## Previewing Web Projects

Since your iPad and Mac are on the same Tailscale network, any dev server running on your Mac is already accessible from your iPad. Just visit `http://<tailscale-hostname>:<port>` in Safari. Make sure your dev server binds to `0.0.0.0` instead of `localhost` (most frameworks have a `--host` flag for this).

The setup script installs a Claude Code skill that knows the correct preview commands for every major framework. Just ask Claude to "preview this project over Tailscale" and it will handle the rest!

**Manual reference**: See [CLAUDE.md](https://github.com/nathangathright/ipad-remote-setup/blob/main/CLAUDE.md) for detailed framework-specific commands (Vite, Next.js, Cloudflare Workers, etc.) and troubleshooting tips.

Need to share a preview with someone outside your Tailscale network? Use [Tailscale Funnel](https://tailscale.com/kb/1223/funnel):

```bash
tailscale funnel 3000
```

This gives you a public `https://<hostname>.<tailnet>.ts.net` URL — no ngrok, no extra accounts, no ephemeral URLs. It's already built into the Tailscale you have installed.

## Questions?

Feel free to reach out if you run into any issues replicating this setup. The automated setup script and documentation are available at [github.com/nathangathright/ipad-remote-setup](https://github.com/nathangathright/ipad-remote-setup).

Happy remote coding!

[^1]: [Remote Claude Code Sessions: How to Work on Your MVP While Pretending to Have a Social Life](https://medium.com/@ajordanbojanic/remote-claude-code-sessions-how-to-work-on-your-mvp-while-pretending-to-have-a-social-life-1a6d28af3c7e)
[^2]: [Claude Code Is Better on Your Phone](https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/)
[^3]: [Claude Code on Phone](https://sealos.io/blog/claude-code-on-phone)

---

*Disclosure: Some links in this post are affiliate links. If you purchase through them, I may earn a small commission at no extra cost to you. I only recommend products I personally use and believe in.*
