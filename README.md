# tailtainer
Tailscale Container Build

only available as `amd64` and `arm64` so they can be built as PIE.

e.g.
```bash
podman volume create tailscaled-state
# for further --env flags check out https://github.com/tailscale/tailscale/blob/main/docs/k8s/run.sh
# e.g. `--env TS_ROUTES=10.0.0.0/24` will advertise routing for the specified subnet.
podman run -d \
  --rm \
  --name tailscaled \
  --hostname $HOSTNAME \
  --env TS_USERSPACE=false \
  --env TS_STATE_DIR=/var/lib/tailscale \
  --env TS_SOCKET=/var/run/tailscale/tailscaled.sock \
  --label "io.containers.autoupdate=registry" \
  --volume tailscaled-state:/var/lib/tailscale \
  --volume /lib/modules:/lib/modules:ro \
  --device /dev/net/tun \
  --network host \
  --privileged `#Highway To The Danger Zone! You could also try --cap-add net_admin,net_raw` \
  ghcr.io/guest42069/tailscale:latest
(cd /etc/systemd/system && podman generate systemd --new --name --files tailscaled) && systemctl enable --now container-tailscaled
podman logs tailscaled
# ... authenticate via provided link in the logs ...
podman exec tailscaled tailscale status
```
