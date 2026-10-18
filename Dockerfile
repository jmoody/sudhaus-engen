FROM --platform=$BUILDPLATFORM ubuntu:26.04 AS build

ARG BUILDARCH
ARG TARGETOS
ARG TARGETARCH

ENV PATH="/usr/local/go/bin:$PATH" \
    GOPATH=/go \
    GOTOOLCHAIN=local

RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl
rm -rf /var/lib/apt/lists/*
EOF

COPY .go-version /tmp/.go-version
RUN <<'EOF' bash
set -euo pipefail
version="$(< /tmp/.go-version)"
tarball="go${version}.linux-${BUILDARCH}.tar.gz"
url="https://dl.google.com/go/${tarball}"
curl -fsSLo "/tmp/${tarball}" "${url}"
echo "$(curl -fsSL "${url}.sha256")  /tmp/${tarball}" | sha256sum --check --strict
tar -C /usr/local -xzf "/tmp/${tarball}"
rm "/tmp/${tarball}"
EOF

WORKDIR /src

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY cmd ./cmd
COPY internal ./internal
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w" -o /out/sudhaus-engen ./cmd/sudhaus-engen

FROM ubuntu:26.04

COPY --from=build /out/sudhaus-engen /usr/local/bin/sudhaus-engen

USER 1000:1000
EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/sudhaus-engen"]
