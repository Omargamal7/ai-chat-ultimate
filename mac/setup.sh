#!/usr/bin/env bash
#
# Set up a private LLM endpoint on this Mac, reachable from your phone over Tailscale.
#
# Ollama stays bound to 127.0.0.1 and is never exposed to the public internet or even to
# the local Wi-Fi network. `tailscale serve` publishes it inside your tailnet only.
#
# Usage:  ./setup.sh            # install, pull a model, start serving
#         ./setup.sh --status   # show what's running and the URL to use
#         ./setup.sh --stop     # stop serving over the tailnet

set -euo pipefail

OLLAMA_PORT=11434

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m!!\033[0m  %s\n' "$1"; }
die()   { printf '\033[1;31mxx\033[0m  %s\n' "$1" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "This script is for macOS. On Linux the same steps work, but install paths differ."

# ---------------------------------------------------------------- model sizing
# Apple Silicon shares one pool of memory between CPU and GPU, so total RAM is what
# constrains model size. Leave roughly 4GB for macOS itself.
mem_bytes=$(sysctl -n hw.memsize)
mem_gb=$((mem_bytes / 1024 / 1024 / 1024))

if   (( mem_gb <= 10 )); then DEFAULT_MODEL="llama3.2:3b";                  SIZE_NOTE="3B is the realistic ceiling here; an 8B would swap and crawl."
elif (( mem_gb <= 20 )); then DEFAULT_MODEL="llama3.1:8b";                  SIZE_NOTE="8B fits comfortably with room for macOS."
else                          DEFAULT_MODEL="qwen2.5:14b-instruct-q4_K_M";  SIZE_NOTE="Enough headroom for a quantized 14B."
fi

MODEL="${MODEL:-$DEFAULT_MODEL}"

# ---------------------------------------------------------------- subcommands
tailnet_url() {
  tailscale serve status 2>/dev/null | grep -oE 'https://[^ ]+' | head -1
}

if [[ "${1:-}" == "--status" ]]; then
  info "Memory: ${mem_gb}GB"
  if pgrep -qx ollama || pgrep -qf 'Ollama.app'; then
    info "Ollama: running"
    ollama list 2>/dev/null | sed 's/^/     /'
  else
    warn "Ollama: not running"
  fi
  url="$(tailnet_url || true)"
  [[ -n "$url" ]] && info "Reachable at: $url" || warn "Not currently served over the tailnet (run ./setup.sh)"
  exit 0
fi

if [[ "${1:-}" == "--stop" ]]; then
  tailscale serve --https=443 off 2>/dev/null || tailscale serve reset 2>/dev/null || true
  info "Stopped serving over the tailnet. Ollama is still running locally on 127.0.0.1:${OLLAMA_PORT}."
  exit 0
fi

# ---------------------------------------------------------------- install
info "Detected ${mem_gb}GB of unified memory -- ${SIZE_NOTE}"
info "Model: ${MODEL}   (override with: MODEL=name ./setup.sh)"
echo

if ! command -v ollama >/dev/null 2>&1; then
  info "Installing Ollama..."
  if command -v brew >/dev/null 2>&1; then
    brew install ollama
  else
    die "Homebrew not found. Install Ollama from https://ollama.com/download then re-run this script."
  fi
else
  info "Ollama already installed."
fi

if ! command -v tailscale >/dev/null 2>&1; then
  # The App Store build keeps its CLI inside the sandboxed bundle; check there before giving up.
  if [[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]]; then
    warn "Tailscale.app found but 'tailscale' is not on your PATH. Add this to your shell profile:"
    echo '      alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"'
    die "Then re-run this script."
  fi
  info "Installing Tailscale..."
  if command -v brew >/dev/null 2>&1; then
    brew install --cask tailscale
  else
    die "Install Tailscale from https://tailscale.com/download/mac then re-run this script."
  fi
else
  info "Tailscale already installed."
fi

# ---------------------------------------------------------------- ollama service
if ! curl -fsS "http://127.0.0.1:${OLLAMA_PORT}" >/dev/null 2>&1; then
  info "Starting Ollama..."
  brew services start ollama 2>/dev/null || { ollama serve >/tmp/ollama.log 2>&1 & }
  for _ in $(seq 1 30); do
    curl -fsS "http://127.0.0.1:${OLLAMA_PORT}" >/dev/null 2>&1 && break
    sleep 1
  done
  curl -fsS "http://127.0.0.1:${OLLAMA_PORT}" >/dev/null 2>&1 \
    || die "Ollama did not start. Check /tmp/ollama.log"
fi
info "Ollama is up on 127.0.0.1:${OLLAMA_PORT}"

if ! ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$MODEL"; then
  info "Pulling ${MODEL} (one time, a few GB)..."
  ollama pull "$MODEL"
else
  info "${MODEL} already present."
fi

# ---------------------------------------------------------------- tailnet
if ! tailscale status >/dev/null 2>&1; then
  warn "Tailscale is not connected yet."
  info "Running 'tailscale up' -- a browser window will open for you to sign in."
  tailscale up
fi

# `serve` is tailnet-only. `funnel` would publish to the public internet -- we never want that here.
info "Publishing Ollama to your tailnet (private -- not the public internet)..."
tailscale serve --bg "${OLLAMA_PORT}"

url="$(tailnet_url || true)"
[[ -n "$url" ]] || die "Could not determine the tailnet URL. Check 'tailscale serve status'."

echo
info "Done. Your private endpoint:"
echo
echo "    ${url}"
echo
echo "  On your phone: install Tailscale, sign in with the same account, then point"
echo "  your chat app at that URL. See ../clients/mobile-setup.md."
echo
echo "  Model: ${MODEL}"
echo "  This URL only resolves for devices signed into your tailnet. It is not public."
echo
warn "A MacBook Air is fanless and sleeps on lid-close -- the endpoint goes down with it."
echo "  To keep it reachable while plugged in:  caffeinate -is"
