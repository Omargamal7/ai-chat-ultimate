# Phone client setup (Nothing Phone / any Android or iOS)

## First: join the tailnet

1. Install **Tailscale** from the Play Store / App Store.
2. Sign in with the **same account** you used on the Mac.
3. Confirm both devices appear in the Tailscale app's device list.

Until this is done the endpoint won't resolve — that's the point, it isn't public.

## Then: point your chat app at the Mac

Use the URL that `mac/setup.sh` printed. It looks like
`https://your-mac.tailXXXX.ts.net` and never changes.

### ChatterUI (Android) / Enchanted (iOS)
1. Settings > API type: **Ollama**.
2. Server URL: `https://your-mac.tailXXXX.ts.net`
3. Leave the API key blank — the tailnet authenticates at the device level with
   WireGuard keys, so there's no token to set.
4. Refresh the model list; the model you pulled should appear.

### Open WebUI Mobile
1. Settings > Connections > Ollama.
2. Server URL: `https://your-mac.tailXXXX.ts.net`
3. Save, then pick the model.

## Notes

- If the app offers "OpenAI Compatible" instead of Ollama, append `/v1` to the URL.
- **Nothing here is on the public internet.** The hostname only resolves for devices
  signed into your tailnet, which is why no bearer token is needed.
- Works over cellular, not just home Wi-Fi — that's what the tailnet buys you over
  plain LAN access.
- If requests start failing, the Mac is almost certainly asleep. Wake it, or keep it
  awake while plugged in with `caffeinate -is`.
- Check state any time with `./setup.sh --status` on the Mac.
