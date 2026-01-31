# iPad Remote Coding Setup

Automated setup script for remote coding from an iPad using Tailscale SSH and tmux.

📖 **[Read the full guide with hardware recommendations and setup details](https://nathangathright.github.io/ipad-remote-setup/)**

## What This Does

This script configures your Mac to be accessible remotely via Tailscale's secure mesh network, allowing you to code from your iPad using an SSH client like Terminus.

Features:
- ✅ Installs and configures Tailscale with SSH support
- ✅ Sets up tmux for persistent sessions
- ✅ Configures SSH keepalive for stable coffee shop WiFi connections
- ✅ Creates a convenient `coffee` alias for quick connection
- ✅ Uses Tailscale's keyless authentication (no SSH keys to manage)

## Quick Start

On your Mac (the one you want to access remotely):

```bash
curl -fsSL https://raw.githubusercontent.com/nathangathright/ipad-remote-setup/main/setup.sh | bash
```

Or download and run locally:

```bash
git clone https://github.com/nathangathright/ipad-remote-setup.git
cd ipad-remote-setup
./setup.sh
```

## What You'll Need

### On Your Mac:
- macOS (any recent version)
- Internet connection
- Admin privileges (for `sudo` commands)

### On Your iPad:
- [Tailscale](https://apps.apple.com/us/app/tailscale/id1470499037) (free)
- [Terminus](https://apps.apple.com/us/app/termius-ssh-client/id549039908) (free tier works great)

## After Running the Script

1. **On your iPad**, install Tailscale and Terminus from the App Store
2. Sign into Tailscale with the same account you used on your Mac
3. Open Terminus and create a new host:
   - **Hostname:** The hostname displayed by the setup script (e.g., `mac-studio`)
   - **Username:** Your Mac username (also displayed by the script)
   - **Authentication:** Leave as default - Tailscale SSH handles it automatically
4. Connect and run: `coffee`

## Daily Workflow

Once set up, your workflow is simple:

1. Open Terminus on your iPad
2. Connect to your Mac
3. Run: `coffee`
4. Start coding with Claude Code (or any other terminal-based tool)

When you're done, just detach from tmux (`Ctrl+B`, then `D`) or close Terminus. Your session keeps running at home.

## The "Coffee" Alias

The script adds a convenient alias to your shell:

```bash
coffee
```

This automatically:
- Attaches to your existing `claude` tmux session if it exists
- Creates a new session and starts Claude Code if it doesn't exist
- Handles all the tmux complexity for you

## Security

- All connections are encrypted through Tailscale's mesh network
- No ports exposed to the public internet
- Tailscale SSH uses keyless authentication (no private keys to manage or leak)
- Your Mac is only accessible to devices on your Tailscale network

## Troubleshooting

**Can't connect from iPad:**
- Verify both devices show as "Connected" in the Tailscale app
- Try using the full MagicDNS hostname (e.g., `mac-studio.tail-scale.ts.net`)
- Check that Tailscale SSH is enabled: `tailscale status | grep ssh`

**Tmux session not found:**
- Create it manually: `tmux new-session -s claude`
- Or just run `coffee` - it will create it automatically

**Connection drops on coffee shop WiFi:**
- The script already configured SSH keepalive for stability
- If issues persist, try reconnecting - Tailscale handles network transitions well

## What Gets Installed

- **Tailscale** (via Homebrew) - Secure mesh VPN
- **tmux** (via Homebrew) - Terminal multiplexer for persistent sessions
- **Configuration files:**
  - `~/.tmux.conf` - tmux settings
  - `~/.zshrc` or `~/.bashrc` - coffee alias
  - `/etc/ssh/sshd_config` - SSH keepalive settings

## Uninstalling

To remove everything installed by this script:

```bash
# Remove Tailscale
brew uninstall tailscale

# Remove tmux
brew uninstall tmux

# Remove config files
rm ~/.tmux.conf

# Remove alias from shell config
# Manually edit ~/.zshrc or ~/.bashrc to remove the coffee alias

# Revert SSH config changes
# Manually edit /etc/ssh/sshd_config to remove ClientAliveInterval settings
```

## Related

For the complete guide including hardware recommendations, shopping list, and detailed setup instructions, see: [Remote Coding from Coffee Shops: iPad Mini + Claude Code Setup](https://nathangathright.github.io/ipad-remote-setup/)

## License

MIT

## Contributing

Found a bug or have a suggestion? Open an issue or submit a pull request!
