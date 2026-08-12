# Colab GPU Bridge

Runs Ollama on Colab's free T4 GPU and exposes it over a static ngrok HTTPS domain, so
phone and desktop clients keep working across Colab restarts without re-entering a new URL.

## One-time setup
1. Create a free ngrok account: https://dashboard.ngrok.com/signup
2. Copy your authtoken: https://dashboard.ngrok.com/get-started/your-authtoken
3. Reserve a free static domain: https://dashboard.ngrok.com/domains
4. In `ollama_bridge.ipynb`, open in Colab, add your authtoken as a Colab secret named
   `NGROK_AUTHTOKEN` (key icon in the left sidebar), and edit `NGROK_DOMAIN` and `MODEL`
   in the CONFIG cell.

## Every session
1. Open `ollama_bridge.ipynb` in Colab.
2. Runtime > Change runtime type > T4 GPU.
3. Runtime > Run all.
4. Wait for "Bridge is live: https://your-domain.ngrok-free.app" in the last cell's output.
5. Point your client at that URL -- see `../clients/continue-config.json` (VS Code) or
   `../clients/mobile-setup.md` (phone apps). Because the domain is static, you only
   need to set the client URL once, ever.

## When Colab disconnects
Free-tier Colab drops idle/long-running GPU sessions on its own schedule (roughly
1.5-3 hours). When that happens, just reopen the notebook and Runtime > Run all again --
the ngrok domain doesn't change, so no client reconfiguration is needed.

## Choosing a model
The T4 has 16GB VRAM. `llama3.1:8b` (the default) fits comfortably with headroom.
For a larger model, try a quantized 14B such as `qwen2.5:14b-instruct-q4_K_M`. Change
the `MODEL` variable in the CONFIG cell and re-run.
