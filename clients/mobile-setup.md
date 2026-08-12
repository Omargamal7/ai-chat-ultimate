# Phone client setup (Nothing Phone / any Android or iOS)

These apps take the bridge URL directly in their settings UI -- no config file needed.

The bridge requires a bearer token, so every client must be configured in
**OpenAI Compatible** mode (which has an API key field) rather than plain Ollama mode.
Use the same `BRIDGE_TOKEN` you stored as a Colab secret.

## Enchanted (iOS) / ChatterUI (Android)
1. Open the app's Settings.
2. API type: **OpenAI Compatible**.
3. Base URL: `https://your-dev-domain.ngrok-free.dev/v1`
4. API key: your `BRIDGE_TOKEN`.
5. Refresh the model list -- the model you pulled in the Colab notebook (e.g. `llama3.1:8b`) should appear.

## Open WebUI Mobile
1. Settings > Connections > **OpenAI API**.
2. API Base URL: `https://your-dev-domain.ngrok-free.dev/v1`
3. API Key: your `BRIDGE_TOKEN`.
4. Save, then select the model from the picker.

## Notes
- The URL above must match `NGROK_DOMAIN` from `colab/ollama_bridge.ipynb` exactly, and keep the `/v1` suffix.
- Because the ngrok dev domain is permanent and the token lives in a Colab secret, both stay the same across restarts -- you configure each client once.
- Treat the token like a password. Anyone holding it *and* the URL can spend your Colab GPU quota. If you think it leaked, change the `BRIDGE_TOKEN` secret in Colab, re-run the notebook, and update your clients.
- If a request suddenly fails, the Colab runtime likely disconnected; re-run the notebook (Runtime > Run all) and the same URL will come back online.
- A `401` means the token is wrong or missing. A `403` means you hit a route the bridge deliberately doesn't expose (model management such as pull/delete).
