# Chat client setup

The model runs on the phone itself, so the client connects to loopback. There is no
server address to look up, no token, and no network involved.

## Android app on the phone

Run `phone/setup.sh` inside the chroot first, then:

### ChatterUI
1. Settings > API type: **Ollama**.
2. Server URL: `http://127.0.0.1:11434`
3. Leave the API key blank — there is no authentication because there is no network path
   from off the device.
4. Refresh the model list; the model you pulled should appear.

### Any OpenAI-compatible client
Use `http://127.0.0.1:11434/v1` and leave the API key blank (or set any placeholder if
the app insists on a non-empty field).

## Notes

- **This works in airplane mode.** If it stops working, the chroot server is down, not
  the network. Check with `./setup.sh --status`.
- Android may kill the chroot under memory pressure after switching to heavy apps.
  Re-running `./setup.sh` restarts it.
- If responses slow down over a long generation, that's thermal throttling, not a bug.
- Some clients reject `127.0.0.1` in a URL field but accept `localhost`, or vice versa.
  Both work.

## Using it from the laptop

Optional, and only worth it if you want the phone's model on a bigger screen. The phone
must be reachable from the laptop, which means either the same Wi-Fi or a private mesh
like Tailscale — and it means binding the server beyond loopback, which reintroduces an
attack surface that the on-device setup doesn't have.

If you do want it, prefer Tailscale over binding to `0.0.0.0`: it authenticates at the
device level and never exposes the port to whatever café Wi-Fi you're on.
