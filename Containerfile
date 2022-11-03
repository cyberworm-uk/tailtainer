FROM docker.io/alpine/git:latest AS source
WORKDIR /go/src
ARG VERSION=release-branch/1.32
RUN git clone --depth=1 -b ${VERSION} https://github.com/tailscale/tailscale.git .
RUN git checkout ${VERSION}
RUN ./build_dist.sh shellvars > shellvars

FROM docker.io/library/golang:1.19-alpine AS build
COPY --from=source /go/src /go/src
WORKDIR /go/src
RUN go mod download
RUN source /go/src/shellvars && CGO_ENABLED=0 go build -tags=ts_omit_aws -buildvcs=false -ldflags "-X tailscale.com/version.Long=$VERSION_LONG -X tailscale.com/version.Short=$VERSION_SHORT -X tailscale.com/version.GitCommit=$VERSION_GIT_HASH -w -s -buildid=" -trimpath -buildmode=pie -o /go/bin/tailscale ./cmd/tailscale
RUN source /go/src/shellvars && CGO_ENABLED=0 go build -tags=ts_omit_aws -buildvcs=false -ldflags "-X tailscale.com/version.Long=$VERSION_LONG -X tailscale.com/version.Short=$VERSION_SHORT -X tailscale.com/version.GitCommit=$VERSION_GIT_HASH -w -s -buildid=" -trimpath -buildmode=pie -o /go/bin/tailscaled ./cmd/tailscaled

FROM docker.io/library/alpine:latest
COPY --from=build /go/bin/* /usr/local/bin/
COPY --from=source /go/src/docs/k8s/run.sh /
RUN apk -U --no-cache upgrade
RUN apk add --no-cache ca-certificates iptables iproute2 ip6tables
CMD [ "/bin/sh", "/run.sh" ]
