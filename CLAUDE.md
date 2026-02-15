# Claude Code Instructions: Web Project Previewing over Tailscale

## Core Concept

When running dev servers for preview over Tailscale, the server MUST bind to `0.0.0.0` (all interfaces) instead of `localhost` or `127.0.0.1`. Servers bound to localhost are only accessible from the same machine.

## Getting the Tailscale Hostname

```bash
# Get the current machine's Tailscale hostname
tailscale status --self | awk 'NR==1 {print $2}'
```

The preview URL will be: `http://<tailscale-hostname>:<port>`

## Framework-Specific Commands

### Vite (Vue, React, Svelte, etc.)

```bash
# Vite binds to localhost by default - must use --host flag
npm run dev -- --host 0.0.0.0

# Or in vite.config.js/ts:
# server: { host: '0.0.0.0' }
```

**Important**: Vite 6+ blocks requests from unrecognized hosts by default. Add the Tailscale hostname to `server.allowedHosts` in your Vite config:

```js
// vite.config.js/ts
export default defineConfig({
  server: {
    host: '0.0.0.0',
    allowedHosts: ['your-tailscale-hostname'],
  },
});
```

**Preview URL**: `http://<tailscale-hostname>:5173`

### Next.js

```bash
# Next.js 13+ defaults to 0.0.0.0, but explicitly set it to be sure
npm run dev -- -H 0.0.0.0

# Or in package.json:
# "dev": "next dev -H 0.0.0.0"
```

**Preview URL**: `http://<tailscale-hostname>:3000`

### Create React App (CRA)

```bash
# Set HOST environment variable
HOST=0.0.0.0 npm start

# Or in .env file:
# HOST=0.0.0.0
```

**Preview URL**: `http://<tailscale-hostname>:3000`

### Cloudflare Workers (wrangler)

```bash
# Wrangler dev binds to localhost by default - use --ip flag
npx wrangler dev --ip 0.0.0.0

# Or in wrangler.toml:
# [dev]
# ip = "0.0.0.0"
```

**Preview URL**: `http://<tailscale-hostname>:8787`

### Astro

```bash
# Use --host flag
npm run dev -- --host 0.0.0.0

# Or in astro.config.mjs:
# server: { host: '0.0.0.0' }
```

**Important**: Astro uses Vite under the hood, and Vite 6+ blocks requests from unrecognized hosts. Add the Tailscale hostname under the `vite` key in `astro.config.mjs`:

```js
// astro.config.mjs
export default defineConfig({
  server: { host: '0.0.0.0' },
  vite: {
    server: {
      allowedHosts: ['your-tailscale-hostname'],
    },
  },
});
```

**Preview URL**: `http://<tailscale-hostname>:4321`

### Python Flask

```python
# app.py
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Preview URL**: `http://<tailscale-hostname>:5000`

### Python Django

```bash
# Must specify 0.0.0.0 explicitly
python manage.py runserver 0.0.0.0:8000
```

**Preview URL**: `http://<tailscale-hostname>:8000`

### Node.js/Express

```javascript
// server.js
app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on 0.0.0.0:3000');
});
```

**Preview URL**: `http://<tailscale-hostname>:3000`

### Static File Servers

```bash
# Python http.server
python3 -m http.server 8000 --bind 0.0.0.0

# npx serve
npx serve -l 3000 --listen 0.0.0.0

# http-server
npx http-server -a 0.0.0.0 -p 8080
```

## Public Sharing with Tailscale Funnel

For sharing previews with people outside your Tailscale network:

```bash
# Make the dev server publicly accessible
tailscale funnel <port>

# Examples:
tailscale funnel 3000   # Next.js
tailscale funnel 5173   # Vite
tailscale funnel 8787   # Wrangler

# This creates a public URL: https://<hostname>.<tailnet>.ts.net
```

**Important**: The dev server still needs to bind to `0.0.0.0` for Funnel to work.

To stop funnel:
```bash
tailscale funnel --bg=false off
```

## Troubleshooting

### "Connection Refused" or "Can't Connect"

**Problem**: Server is binding to localhost instead of 0.0.0.0

**Solution**: Check the server startup logs. If you see:
- ❌ `http://localhost:3000` or `http://127.0.0.1:3000` → WRONG
- ✅ `http://0.0.0.0:3000` or shows network interfaces → CORRECT

Add the appropriate `--host` flag or config option for your framework.

### Firewall Issues

macOS may prompt to allow incoming connections the first time. Click "Allow".

### Wrong Hostname

If `tailscale status` shows an unexpected hostname, you can set a custom one:
```bash
sudo tailscale up --hostname=my-mac
```

## Quick Reference

| Framework | Command | Port |
|-----------|---------|------|
| Vite | `npm run dev -- --host 0.0.0.0` | 5173 |
| Next.js | `npm run dev -- -H 0.0.0.0` | 3000 |
| Wrangler | `npx wrangler dev --ip 0.0.0.0` | 8787 |
| Astro | `npm run dev -- --host 0.0.0.0` | 4321 |
| Django | `python manage.py runserver 0.0.0.0:8000` | 8000 |

## General Pattern

When helping users preview web projects:

1. **Always** include the `--host 0.0.0.0` flag (or equivalent)
2. **Always** get the Tailscale hostname using `tailscale status --self`
3. **Always** provide the complete Tailscale preview URL
4. **Vite/Astro**: Add the Tailscale hostname to `server.allowedHosts` in the Vite config (Vite 6+ blocks unrecognized hosts by default)
5. **Suggest** Tailscale Funnel if they need to share publicly

Remember: The most common mistake is forgetting to bind to 0.0.0.0!
