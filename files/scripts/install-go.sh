#!/usr/bin/env bash
set -euo pipefail

GO_VERSION="1.26.3"

ARCH="$(uname -m)"

case "${ARCH}" in
  x86_64)
    GO_ARCH="amd64"
    ;;
  aarch64)
    GO_ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: ${ARCH}"
    exit 1
    ;;
esac

GO_TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"

echo "Installing Go ${GO_VERSION} for ${ARCH}..."

curl -fsSL "${GO_URL}" -o "/tmp/${GO_TARBALL}"

rm -rf /usr/lib/go
tar -C /usr/lib -xzf "/tmp/${GO_TARBALL}"

ln -sf /usr/lib/go/bin/go /usr/bin/go
ln -sf /usr/lib/go/bin/gofmt /usr/bin/gofmt

cat >/etc/profile.d/go.sh <<'EOF'
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$PATH:$GOPATH/bin"
EOF

go version