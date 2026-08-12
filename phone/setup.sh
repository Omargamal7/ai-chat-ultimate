#!/usr/bin/env bash
#
# Run an LLM directly on the phone, inside a rooted Linux chroot.
#
# There is no network in this design. A chroot shares the host network namespace, so
# Android apps reach the model on 127.0.0.1 -- no tunnel, no VPN, no server, no internet.
# It works in airplane mode.
#
# Usage:  ./setup.sh              # install, pull a model sized to free RAM, serve
#         ./setup.sh --status     # what's running
#         ./setup.sh --stop       # stop the server
#         ./setup.sh --bench      # measure tokens/sec for the installed model

set -euo pipefail

PORT=11434

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$1"; }
die()  { printf '\033[1;31mxx\033[0m  %s\n' "$1" >&2; exit 1; }

arch="$(uname -m)"
[[ "$arch" == "aarch64" || "$arch" == "arm64" ]] \
  || warn "Expected aarch64, found ${arch}. Continuing, but this script targets ARM64 Android."

# chroot changes the filesystem root but not the environment, so a TMPDIR inherited from
# the host shell (e.g. Termux's /data/data/com.termux/files/usr/tmp) can point at a path
# that doesn't exist inside the chroot at all, which breaks mktemp for apt and installers.
if [[ -n "${TMPDIR:-}" && ! -d "$TMPDIR" ]]; then
  warn "TMPDIR=${TMPDIR} doesn't exist in this chroot (inherited from the host shell); using /tmp instead."
  unset TMPDIR
fi
mkdir -p /tmp
chmod 1777 /tmp 2>/dev/null || true

# ---------------------------------------------------------------- memory sizing
# What matters is MemAvailable, not MemTotal: Android keeps a large share of the 12GB for
# the UI and background apps, and the chroot only sees what is genuinely free.
#
# Model weights must fit in physical RAM. Swap does NOT help here -- a forward pass reads
# nearly every weight once per token, so any part of the model living on storage costs
# gigabytes of I/O per token and drops you to a fraction of a token per second.
avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
avail_gb=$(( avail_kb / 1024 / 1024 ))
total_gb=$(( total_kb / 1024 / 1024 ))

# Leave ~1.5GB of headroom for the KV cache and for Android not to start killing apps.
if   (( avail_kb > 7000000 )); then DEFAULT_MODEL="llama3.1:8b";  NOTE="8B fits with headroom."
elif (( avail_kb > 4000000 )); then DEFAULT_MODEL="llama3.2:3b";  NOTE="3B is the safe choice at this free-memory level."
elif (( avail_kb > 2000000 )); then DEFAULT_MODEL="llama3.2:1b";  NOTE="Tight -- 1B only. Close background apps and re-run for a larger model."
else die "Only ${avail_gb}GB available. Close apps and try again; there is not enough free RAM to run a model."
fi

MODEL="${MODEL:-$DEFAULT_MODEL}"

# ---------------------------------------------------------------- subcommands
case "${1:-}" in
  --status)
    info "RAM: ${avail_gb}GB available of ${total_gb}GB total"
    if curl -fsS "http://127.0.0.1:${PORT}" >/dev/null 2>&1; then
      info "Server: running on 127.0.0.1:${PORT}"
      ollama list 2>/dev/null | sed 's/^/     /'
    else
      warn "Server: not running"
    fi
    swap_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    (( swap_kb > 0 )) && warn "Swap is on ($(( swap_kb / 1024 ))MB). It will not speed up inference; see README."
    exit 0
    ;;
  --stop)
    pkill -f 'ollama serve' 2>/dev/null && info "Stopped." || warn "Nothing was running."
    exit 0
    ;;
  --bench)
    command -v ollama >/dev/null || die "Ollama is not installed yet. Run ./setup.sh first."
    info "Benchmarking ${MODEL} -- this reflects real sustained speed, including thermal throttling."
    ollama run "$MODEL" --verbose "Write one paragraph about the sea." 2>&1 | tail -8
    exit 0
    ;;
esac

# ---------------------------------------------------------------- install
info "RAM: ${avail_gb}GB available of ${total_gb}GB total -- ${NOTE}"
info "Model: ${MODEL}   (override with: MODEL=name ./setup.sh)"
echo

if ! command -v ollama >/dev/null 2>&1; then
  info "Installing Ollama for arm64..."
  command -v curl >/dev/null || die "curl is required. Install it in the chroot first (apt install curl)."
  curl -fsSL https://ollama.com/install.sh | sh
else
  info "Ollama already installed."
fi

# ---------------------------------------------------------------- serve
if ! curl -fsS "http://127.0.0.1:${PORT}" >/dev/null 2>&1; then
  info "Starting the server on 127.0.0.1:${PORT} (loopback only)..."
  # Bound to loopback deliberately. Android apps on this device can still reach it,
  # because a chroot shares the host network namespace -- but nothing off-device can.
  OLLAMA_HOST="127.0.0.1:${PORT}" nohup ollama serve >/tmp/ollama.log 2>&1 &
  for _ in $(seq 1 30); do
    curl -fsS "http://127.0.0.1:${PORT}" >/dev/null 2>&1 && break
    sleep 1
  done
  curl -fsS "http://127.0.0.1:${PORT}" >/dev/null 2>&1 || die "Server did not start. Check /tmp/ollama.log"
fi
info "Server is up."

if ! ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$MODEL"; then
  info "Pulling ${MODEL}..."
  ollama pull "$MODEL"
else
  info "${MODEL} already present."
fi

echo
info "Done. The model is running on this phone."
echo
echo "    Endpoint : http://127.0.0.1:${PORT}"
echo "    Model    : ${MODEL}"
echo
echo "  In an Android chat app (ChatterUI, etc.) set the server to that address."
echo "  No tunnel, no VPN, no account. It works in airplane mode."
echo
echo "  Measure real speed with:  ./setup.sh --bench"
echo
warn "Sustained generation heats the phone and it will throttle. Expect the first"
echo "  minute to be faster than the fifth. Charging while generating makes it worse."
