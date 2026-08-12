# Private LLM endpoint: MacBook + Tailscale

Runs a model on your own Mac and makes it reachable from your phone anywhere, over a
private network. Nothing is exposed to the public internet at any point.

```
┌────────────────────────┐         ┌──────────────────────┐         ┌────────────────────┐
│   MacBook Air (M2)     │         │   Tailscale mesh     │         │  Nothing Phone (2) │
│                        │         │                      │         │                    │
│  Ollama on 127.0.0.1   │ ──────> │  Private WireGuard   │ ──────> │  Chat client       │
│  Metal / unified mem   │         │  No public exposure  │         │  Stable hostname   │
└────────────────────────┘         └──────────────────────┘         └────────────────────┘
```

## Why this over a Colab tunnel

| | Colab + ngrok | This |
|---|---|---|
| Terms of service | Disallowed on free tier | Your hardware, no restrictions |
| Public exposure | Public HTTPS URL, scannable | None -- tailnet only |
| Session limits | Dies every few hours | None |
| Privacy | Google runs the GPU | Nothing leaves your devices |
| Per-session setup | Re-run the notebook | None, it's a daemon |
| URL stability | Rotates unless reserved | Permanent MagicDNS name |

Colab's [FAQ](https://research.google.com/colaboratory/faq.html) disallows "bypassing the
notebook UI to interact primarily via a web UI" on the free tier, and "connecting to
remote proxies" for everyone. A phone talking to a tunnel into Colab is exactly that.
This design has no such problem -- it is your own machine on your own network.

## Setup

```bash
./setup.sh
```

The script installs Ollama and Tailscale if missing, picks a model sized to your RAM,
starts Ollama on `127.0.0.1`, and publishes it to your tailnet with `tailscale serve`.
It prints the URL to give your phone.

Then on the phone: install Tailscale, sign in with the **same account**, and point your
chat app at that URL. See [`../clients/mobile-setup.md`](../clients/mobile-setup.md).

```bash
./setup.sh --status   # what's running, and the URL
./setup.sh --stop     # stop serving over the tailnet
MODEL=qwen2.5:7b ./setup.sh   # override the model choice
```

## What your RAM can run

Apple Silicon shares one memory pool between CPU and GPU, so total RAM is the constraint.
Budget about 4GB for macOS itself.

| Mac memory | Practical model | Notes |
|---|---|---|
| 8 GB | `llama3.2:3b` | 3B is the ceiling. An 8B technically loads but swaps and crawls. |
| 16 GB | `llama3.1:8b` | Comfortable, this is the sweet spot. |
| 24 GB+ | `qwen2.5:14b-instruct-q4_K_M` | Quantized 14B fits with headroom. |

Check yours with `sysctl -n hw.memsize` (bytes) — the script does this automatically.

Expect roughly 10-25 tokens/sec for an 8B on an M2, slower than a datacenter T4 but
perfectly usable for chat, and it never disconnects.

## Honest limitations

- **The Air is fanless.** Sustained generation will thermally throttle. Fine for
  interactive chat, poor for long batch jobs.
- **Lid-close sleeps the machine** and the endpoint goes with it. `caffeinate -is` keeps
  it awake while plugged in. This is the real cost of using a laptop as a server.
- **Battery.** Inference is expensive; run it plugged in if you want it available.
- **Small models are small.** A 3B or 8B is meaningfully weaker at reasoning than a
  frontier model. Local and private is a real win; it is not a capability win.

## Security notes

`tailscale serve` publishes only inside your tailnet. Do **not** substitute
`tailscale funnel` — that puts it on the public internet and reintroduces every problem
this design avoids.

Ollama stays bound to `127.0.0.1`, so even on untrusted Wi-Fi nothing on the local
network can reach it. Because the tailnet is authenticated at the device level by
WireGuard keys, there is no bearer token to manage, leak, or rotate.
