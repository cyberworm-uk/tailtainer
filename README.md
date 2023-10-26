# tailtainer
[Tailscale](https://tailscale.com/) Container Build

This container is more or less the same as the [official image](https://hub.docker.com/r/tailscale/tailscale). As such you could change `ghcr.io/guest42069/tailscale:latest` to `docker.io/tailscale/tailscale:latest` in these instructions to use their provided container images.

This image omits the AWS integrtion and builds the tailscale cli functionality into the tailscaled binary to shave a few MB off of the image size.

Further configuration options are available though [environment variables](https://github.com/tailscale/tailscale/blob/v1.50.1/cmd/containerboot/main.go#L6-L52)

## Examples

### podman run ... / docker run ...
```bash
podman volume create tailscaled-state
podman run -d \
  --rm \
  --name tailscaled \
  --env TS_USERSPACE=false \
  --env TS_STATE_DIR=/var/lib/tailscale \
  --env TS_SOCKET=/var/run/tailscale/tailscaled.sock \
  --env TS_AUTH_ONCE=true \
  --env TS_ACCEPT_DNS=true \
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

### [quadlets](https://www.redhat.com/sysadmin/quadlet-podman)

Quadlet's are functionally equivalent to `podman generate systemd ...` but the idea is to have a plugin to systemd to generate `.service` units from configuration files.
This means that in future if better ways of managing containers occur, or preferred defaults change, the `.service` files don't need to be regenerated manually.

In the below case, creating these files would result in the creation of `tailscaled.service` and `tailscaled-volume.service` which when run will create the `systemd-tailscaled` container and volume respectively.

`/etc/container/systemd/tailscaled.container`
```.service
[Unit]
Description=Tailscale container

[Container]
# image
Image=ghcr.io/guest42069/tailscale:latest
AutoUpdate=registry

# storage and host resouces
Volume=tailscaled.volume:/var/lib/tailscale
Volume=/lib/modules:/lib/modules:ro
AddDevice=/dev/net/tun

# capabilities
AddCapability=NET_RAW NET_ADMIN SYS_MODULE
Network=host

# configuration
Environment=TS_USERSPACE=false
Environment=TS_STATE_DIR=/var/lib/tailscale
Environment=TS_SOCKET=/var/run/tailscale/tailscaled.sock
Environment=TS_AUTH_ONCE=true
Environment=TS_ACCEPT_DNS=true

[Service]
Restart=always
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target
```

`/etc/container/systemd/tailscaled.volume`
```.service
[Volume]
# This space intentionally left blank, to create a default volume.
```

Once those files are in place, the associated `.service` units will be generated every time `systemctl daemon-reload` is called (e.g. on boot, or manually run if you've made changes).
