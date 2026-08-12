# Phone client setup (Nothing Phone / any Android or iOS)

These apps take the bridge URL directly in their settings UI -- no config file needed.

## Enchanted (iOS) / ChatterUI (Android)
1. Open the app's Settings.
2. API type: **Ollama** (or "OpenAI Compatible" if Ollama isn't listed).
3. Base URL / Host: `https://your-reserved-domain.ngrok-free.app`
4. Leave the API key blank (Ollama doesn't require one by default).
5. Refresh the model list -- the model you pulled in the Colab notebook (e.g. `llama3.1:8b`) should appear.

## Open WebUI Mobile
1. Settings > Connections > Ollama.
2. Server URL: `https://your-reserved-domain.ngrok-free.app`
3. Save, then select the model from the picker.

## Notes
- The URL above must match `NGROK_DOMAIN` from `colab/ollama_bridge.ipynb` exactly.
- Because the domain is reserved (static), you only enter it once -- it survives Colab restarts.
- If a request suddenly fails, the Colab runtime likely disconnected; re-run the notebook (Runtime > Run all) and the same URL will come back online.
