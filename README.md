# ai-chat-ultimate

An LLM running on your own phone. No server, no tunnel, no account, no internet.

```
┌─────────────────────────────────────────────┐
│           Nothing Phone (2), 12GB           │
│                                             │
│   Android app  ──>  127.0.0.1:11434         │
│                          │                  │
│                     Linux chroot            │
│                     Ollama + model          │
└─────────────────────────────────────────────┘
```

## Start here

Inside the chroot:

```bash
cd phone && ./setup.sh
```

Then point an Android chat client at `http://127.0.0.1:11434`.

Full guide: [`phone/README.md`](phone/README.md).

## Layout

| Path | What it is |
|---|---|
| [`phone/`](phone/) | **The setup.** Model runs on-device in the chroot. |
| [`clients/`](clients/) | Chat client configuration. |
| [`colab/`](colab/) | Abandoned Colab + ngrok approach, kept for reference behind a warning. |

## How this got here

The project began as a bridge to Google Colab's free T4, on the assumption that inference
had to happen on a remote GPU. Three findings dismantled that:

1. **Colab's terms disallow it.** The [FAQ](https://research.google.com/colaboratory/faq.html)
   prohibits *"bypassing the notebook UI to interact primarily via a web UI"* on the free
   tier and *"connecting to remote proxies"* for everyone. Serving a phone through a
   tunnel is exactly that, and enforcement costs the Google account it runs on.

2. **Exposing Ollama publicly is unsafe.** It ships no authentication, so a tunnel put an
   open inference and model-management API on the internet behind a permanent URL.

3. **The remote GPU was never needed.** The phone has 12GB of RAM and a 2022 flagship SoC
   — more memory and more compute than the 2013 laptop it was meant to serve. Running the
   model on the phone deletes the tunnel, the domain, the token, and the session limits
   all at once.

The result is smaller than any intermediate design: one script, one loopback socket, no
network.

## Two things worth knowing

**Swap does not help.** Each token requires a forward pass that reads nearly every weight,
so any part of the model held on storage costs gigabytes of I/O *per token*. Weights and
KV cache must fit in physical RAM. Details in [`phone/README.md`](phone/README.md).

**Thermals set the real speed.** A fanless phone throttles under sustained generation.
Benchmark your own device with `./setup.sh --bench` rather than trusting published
numbers.
