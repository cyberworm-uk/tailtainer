# tailtainer
Tailscale Container Build

only available as `amd64` and `arm64` so they can be built as PIE.

e.g.
```bash
podman volume create tailscaled-state
podman run -d \
  --rm \
  --name tailscaled \
  --hostname $HOSTNAME \
  --label "io.containers.autoupdate=registry" \
  --volume tailscaled-state:/var/lib/tailscale \
  --device /dev/net/tun \
  --network host \
  --privileged `#Highway To The Danger Zone! You could also try --cap-add net_admin,net_raw` \
  ghcr.io/guest42069/tailscale:latest tailscaled --state /var/lib/tailscale/tailscaled.state
(cd /etc/systemd/system && podman generate systemd --new --name --files tailscaled) && systemctl enable --now container-tailscaled
podman exec tailscaled tailscale up
# ... authenticate via provided link ...
podman exec tailscaled tailscale status
```
