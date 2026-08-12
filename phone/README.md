# On-device LLM: Nothing Phone (2), root + chroot

The model runs on the phone itself. There is no server, no tunnel, no VPN, and no
internet connection anywhere in the path.

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

A chroot shares the host's network namespace, so an ordinary Android app can reach a
server bound to loopback inside the chroot. That single fact removes every networking
component this repo previously needed.

## Setup

Inside the chroot:

```bash
./setup.sh
```

It installs Ollama for arm64, picks a model that fits free RAM, and serves on loopback.
Then point any Android chat client at `http://127.0.0.1:11434`.

```bash
./setup.sh --status   # RAM, server state, installed models
./setup.sh --bench    # real tokens/sec, including throttling
./setup.sh --stop
MODEL=llama3.2:3b ./setup.sh
```

## Why the phone and not the MacBook

| | MacBookAir6,2 (2013) | Nothing Phone (2) |
|---|---|---|
| RAM | 4 GB (~1 GB free under Big Sur) | 12 GB |
| CPU | 2-core Haswell, 2013 | 8-core Snapdragon 8+ Gen 1, 2022 |
| Matrix instructions | none useful | NEON / i8mm |
| Max OS | Big Sur, out of support | current |

The 2013 Air cannot host a useful model — 4GB of RAM with roughly 1GB free after the OS
leaves no room for weights. The phone has three times the memory and a far newer core.

## Swap will not help — and this is the exception to the usual rule

Adding swap is normally a reasonable way to cope with limited RAM. For LLM inference it
is close to useless, and it is worth understanding why before spending 12GB of storage
on it.

Generating **one token** requires a full forward pass, which reads **nearly every weight
in the model**. That happens again for the next token, and the next. So the entire model
is touched once per token, continuously.

If part of the model lives in swap, every token pays for that in storage reads:

| Model resident in RAM | Result |
|---|---|
| 100% | Normal speed |
| 75% | Gigabytes read per token — seconds per token |
| 50% | Effectively unusable |

The rule is hard: **weights plus KV cache must fit in physical RAM.** Swap changes
whether a model *loads*, not whether it *runs*.

You don't need it anyway. An 8B at Q4 is about 4.7GB and fits in 12GB alongside Android.

## What fits

Sized against *free* memory, not total — Android holds several GB for the UI and
background apps. `./setup.sh --status` shows the real number.

| Free RAM | Model | Rough speed on 8+ Gen 1 |
|---|---|---|
| 7 GB+ | `llama3.1:8b` | slowest, most capable |
| 4-7 GB | `llama3.2:3b` | good balance |
| 2-4 GB | `llama3.2:1b` | fastest, least capable |

Closing background apps before starting genuinely moves you up a tier. Run `--bench` on
your own device rather than trusting any published figure; sustained speed on a phone
depends on thermals more than on the chip.

## Honest limitations

- **Thermal throttling is the dominant factor.** A phone has no fan. The first minute of
  generation is faster than the fifth, and long outputs slow down as it heats.
- **Battery drain is heavy.** Inference pins multiple cores.
- **Charging while generating** adds heat and makes throttling worse. Prefer one or the
  other.
- **Android may kill the chroot** under memory pressure if you switch to heavy apps.
- **Small models are small.** A 3B or 8B is meaningfully weaker at reasoning than a
  frontier model. On-device and fully private is a real win; it is not a capability win.

## What this buys you

- No account, no quota, no terms of service, nothing to violate.
- No tunnel, no reserved domain, no bearer token, no attack surface — there is no
  listening socket reachable from off the device.
- Works with the radio off, on a plane, underground.
- Prompts never leave the phone.
