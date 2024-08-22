FROM --platform=$BUILDPLATFORM docker.io/library/golang:alpine AS build
WORKDIR /go/src
ARG VERSION=release-branch/1.72 TARGETOS TARGETARCH
ENV GOOS="$TARGETOS" GOARCH="$TARGETARCH" GOFLAGS="-tags=ts_include_cli -buildvcs=false -trimpath"
RUN apk add --no-cache git
RUN git clone --depth=1 -b ${VERSION} https://github.com/tailscale/tailscale.git . && git checkout ${VERSION}
RUN --mount=type=cache,target=/go/pkg ./build_dist.sh shellvars > shellvars
RUN --mount=type=cache,target=/go/pkg go mod download
RUN --mount=type=cache,target=/go/pkg --mount=type=cache,target=/root/.cache/go-build source /go/src/shellvars && go build -ldflags "-X tailscale.com/version.longStamp=$VERSION_LONG -X tailscale.com/version.shortStamp=$VERSION_SHORT -w -s -buildid=" ./cmd/tailscaled
RUN --mount=type=cache,target=/go/pkg --mount=type=cache,target=/root/.cache/go-build source /go/src/shellvars && go build -ldflags "-X tailscale.com/version.longStamp=$VERSION_LONG -X tailscale.com/version.shortStamp=$VERSION_SHORT -w -s -buildid=" ./cmd/containerboot

FROM docker.io/library/alpine:latest
LABEL org.opencontainers.image.base.name="docker.io/library/alpine"
LABEL org.opencontainers.image.title="Tailscale"
LABEL org.opencontainers.image.description="Tailscale Container"
RUN apk add --no-cache ca-certificates iptables iproute2 ip6tables iputils && ln -s /usr/local/bin/tailscaled /usr/local/bin/tailscale && ln -s /usr/local/bin/containerboot /run.sh
COPY --from=build /go/src/tailscaled /usr/local/bin/
COPY --from=build /go/src/containerboot /usr/local/bin/
CMD [ "/usr/local/bin/containerboot" ]
