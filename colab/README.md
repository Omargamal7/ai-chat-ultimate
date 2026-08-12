# Colab GPU Bridge

Runs Ollama on Colab's free T4 GPU and exposes it over a static ngrok HTTPS domain, so
phone and desktop clients keep working across Colab restarts without re-entering a new URL.

Ollama ships no authentication of its own, so the tunnel does not point at it directly.
A small reverse proxy sits in front of Ollama and is what gets tunnelled: it requires a
bearer token on every request and only forwards inference and read-only routes. Model
management (`/api/pull`, `/api/push`, `/api/delete`, `/api/create`, `/api/copy`) is not
reachable from the internet at all. Ollama itself stays bound to `127.0.0.1`.

## One-time setup
1. Create a free ngrok account: https://dashboard.ngrok.com/signup
2. Copy your authtoken: https://dashboard.ngrok.com/get-started/your-authtoken
3. Look up your free static domain: https://dashboard.ngrok.com/domains
   Every account is given one automatically, shown as a **dev domain** in the format
   `something-random.ngrok-free.dev`. There is nothing to create -- don't click
   New Domain, since choosing your own name is a paid feature. The auto-assigned
   name is random but permanent, which is all this setup needs.
4. Invent a bridge token -- a long random string:
   `python -c "import secrets; print(secrets.token_urlsafe(32))"`
5. Open `ollama_bridge.ipynb` in Colab and add both as Colab secrets (key icon in the
   left sidebar), with notebook access enabled:
   - `NGROK_AUTHTOKEN` -- from step 2
   - `BRIDGE_TOKEN` -- from step 4
6. Edit `NGROK_DOMAIN` and `MODEL` in the CONFIG cell.

Keeping the token in a Colab secret is what makes it stable across restarts. If the
notebook can't find the secret it generates a throwaway token and prints it, which works
but forces you to reconfigure every client on each restart.

## Every session
1. Open `ollama_bridge.ipynb` in Colab.
2. Runtime > Change runtime type > T4 GPU.
3. Runtime > Run all.
4. Wait for "Bridge is live: https://your-dev-domain.ngrok-free.dev" in the tunnel cell's output.
5. Your clients are already pointed at that URL with the token -- see
   `../clients/continue-config.json` (VS Code) or `../clients/mobile-setup.md` (phone apps).
   Because the domain and token are both static, you only set them once, ever.

The proxy cell self-tests before the tunnel opens: it asserts that an unauthenticated
request gets 401, an authenticated one gets 200, and `/api/delete` gets 403. If any of
those assertions fail the notebook stops there rather than exposing the port.

## Security notes
- Never commit your real `BRIDGE_TOKEN`. `clients/continue-config.json` ships a
  placeholder; fill it in only in your local `~/.continue/config.json`.
- The token is the only thing standing between a scanned or leaked URL and your GPU
  quota. The ngrok dev domain is permanent, which is exactly why the token matters
  more here than it would with a rotating quick tunnel.
- To rotate: change the `BRIDGE_TOKEN` Colab secret, re-run the notebook, update clients.

## When Colab disconnects
Free-tier Colab drops idle/long-running GPU sessions on its own schedule (roughly
1.5-3 hours). When that happens, just reopen the notebook and Runtime > Run all again --
the ngrok domain and token don't change, so no client reconfiguration is needed.

## Choosing a model
The T4 has 16GB VRAM. `llama3.1:8b` (the default) fits comfortably with headroom.
For a larger model, try a quantized 14B such as `qwen2.5:14b-instruct-q4_K_M`. Change
the `MODEL` variable in the CONFIG cell and re-run.

## A note on tab autocomplete
The Continue config intentionally sets up chat only. Pointing tab-autocomplete at this
bridge fires a request on almost every keystroke, across a tunnel, at a chat-tuned model
that isn't built for fill-in-the-middle -- slow results and a lot of burned Colab quota.
Run a small local model for autocomplete instead if you want it.
