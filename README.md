# tailtainer
Tailscale Container Build

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
  --cap-add=NET_ADMIN --cap-add=NET_RAW --cap-add=SYS_MODULE \
  ghcr.io/guest42069/tailscale:latest
(cd /etc/systemd/system && podman generate systemd --new --name --files tailscaled) && systemctl enable --now container-tailscaled
podman logs tailscaled
# ... authenticate via provided link in the logs ...
podman exec tailscaled tailscale status
```

## [quadlets](https://www.redhat.com/sysadmin/quadlet-podman)

`/etc/container/systemd/tailscaled.container`
```.service
[Unit]
Description=Tailscale container

[Container]
# image
Image=ghcr.io/guest42069/tailscale:latest
AutoUpdate=registry

# storage and host resouces
Volume=tailscaled-state.volume:/var/lib/tailscale
Volume=/lib/modules:/lib/modules:ro
AddDevice=/dev/net/tun

# capabilities
AddCapability=NET_RAW NET_ADMIN SYS_MODULE
Network=host

# configuration
Environment=TS_USERSPACE=false
Environment=TS_STATE_DIR=/var/lib/tailscale
Environment=TS_EXTRA_ARGS="--accept-routes --accept-dns"
Environment=TS_SOCKET=/var/run/tailscale/tailscaled.sock

[Service]
Restart=always
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target
```

`/etc/container/systemd/tailscaled-state.volume`
```.service
[Volume]
# This space intentionally left blank, to create a default volume.
```
