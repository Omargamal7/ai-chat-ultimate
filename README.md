# ai-chat-ultimate

A private LLM endpoint you own, reachable from your phone anywhere.

```
┌────────────────────────┐         ┌──────────────────────┐         ┌────────────────────┐
│      Your Mac          │         │   Tailscale mesh     │         │       Phone        │
│                        │         │                      │         │                    │
│  Ollama on 127.0.0.1   │ ──────> │  Private WireGuard   │ ──────> │  Chat client       │
│  Metal / unified mem   │         │  No public exposure  │         │  Stable hostname   │
└────────────────────────┘         └──────────────────────┘         └────────────────────┘
```

Nothing is exposed to the public internet at any point.

## Start here

```bash
cd mac && ./setup.sh
```

Then follow [`clients/mobile-setup.md`](clients/mobile-setup.md) on your phone.

Full guide: [`mac/README.md`](mac/README.md).

## Layout

| Path | What it is |
|---|---|
| [`mac/`](mac/) | **The recommended setup.** Ollama on your own machine, served over Tailscale. |
| [`clients/`](clients/) | Phone and VS Code client configuration. |
| [`colab/`](colab/) | Earlier Colab + ngrok approach. Kept for reference — see the warning in its README before using it. |

## Why not run it on Colab's free GPU

That was this repo's original design, and it was abandoned for a good reason. Colab's
[FAQ](https://research.google.com/colaboratory/faq.html) disallows *"bypassing the
notebook UI to interact primarily via a web UI"* on the free tier and *"connecting to
remote proxies"* for everyone — which is precisely what tunnelling inference to a phone
does. Building on it risks the Google account you use for everything else.

Running on your own Mac is slower in raw tokens/sec and caps model size at what your RAM
holds. In exchange there is no terms-of-service conflict, no public attack surface, no
session that dies every few hours, and no third party seeing your prompts. For a personal
assistant that trade is worth it.
