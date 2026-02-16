# Claude Code Instructions

## Web Project Previewing over Tailscale

This project installs the [tailserve](https://github.com/nathangathright/tailserve) skill, which provides comprehensive guidance on previewing web projects over Tailscale. The skill content is maintained in the standalone repo — see its `SKILL.md` for full details.

Key points:
- Dev servers must bind to `0.0.0.0` for direct tailnet access (most frameworks have a `--host` flag)
- `tailscale serve` is recommended for multiple projects (no `0.0.0.0` needed, automatic HTTPS)
- `tailscale funnel` extends serve for public sharing
- Get the Tailscale hostname with: `tailscale status --self | awk 'NR==1 {print $2}'`
