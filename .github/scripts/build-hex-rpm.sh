#!/usr/bin/env bash
# Build a system-wide RPM for anomalyco/hex on Fedora.
#
# Runs INSIDE a Fedora container (see .github/workflows/hex-rpm.yml). Expects the
# current working directory to be a checkout of anomalyco/hex. The finished RPM
# is written to $HEX_OUT as hex.x86_64.rpm with a stable name so the recipe can
# reference a fixed release URL.
set -euo pipefail

src=$PWD
out=${HEX_OUT:-/out}

if [ ! -f "$src/Cargo.toml" ]; then
  echo "Cargo.toml not found in $src; run from a hex checkout." >&2
  exit 1
fi

version=$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$src/Cargo.toml" | head -1)
if [ -z "$version" ]; then
  echo "Could not read version from Cargo.toml." >&2
  exit 1
fi

echo "==> Installing build dependencies (Fedora $(rpm -E %fedora))"
dnf install -y --setopt=install_weak_deps=False \
  cargo rust clang cmake pkgconf-pkg-config python3 \
  alsa-lib-devel gtk3-devel gtk-layer-shell-devel \
  libappindicator-gtk3-devel libxkbcommon-devel libxkbcommon-x11-devel \
  libX11-devel libxcb-devel libudev-devel openblas-devel \
  openssl-devel vulkan-loader-devel vulkan-headers \
  glslc libshaderc-devel spirv-headers-devel fontconfig-devel freetype-devel \
  wl-clipboard wtype curl jq vim-common rpm-build

export BLA_VENDOR=OpenBLAS
export OPENSSL_NO_VENDOR=1
export CC=clang
export CXX=clang++

echo "==> Building hex $version"
cargo build --locked --release

binary=$src/target/release/voice-control
if [ ! -x "$binary" ]; then
  echo "Build did not produce $binary" >&2
  exit 1
fi

topdir=$src/rpmbuild
mkdir -p "$topdir"/{BUILD,RPMS,SOURCES,SPECS,SRPMS} "$out"
install -m0644 "$src/packaging/hex.desktop" "$topdir/SOURCES/hex.desktop"

cat > "$topdir/SPECS/hex.spec" <<SPEC
%global debug_package %{nil}

Name:           hex
Version:        $version
Release:        1%{?dist}
Summary:        Local-first voice dictation (Linux beta)
License:        MIT
URL:            https://github.com/anomalyco/hex
BuildArch:      x86_64

Requires:       gtk3
Requires:       gtk-layer-shell
Requires:       alsa-lib
Requires:       libxkbcommon
Requires:       libxkbcommon-x11
Requires:       openblas
Requires:       vulkan-loader
Requires:       wl-clipboard
Requires:       wtype

%description
HEX is a local-first voice dictation application. The Linux beta targets
x86_64 X11 sessions and wlroots-based Wayland compositors such as Hyprland
and Sway. This package installs the \`hex\` binary system-wide; models are
installed per user with \`hex model install\`.

%install
install -Dpm0755 $binary %{buildroot}%{_bindir}/hex
install -Dpm0644 $topdir/SOURCES/hex.desktop %{buildroot}%{_datadir}/applications/hex.desktop
sed -i 's|@HEX_BIN@|%{_bindir}/hex|' %{buildroot}%{_datadir}/applications/hex.desktop

%files
%{_bindir}/hex
%{_datadir}/applications/hex.desktop
SPEC

echo "==> Packaging RPM"
rpmbuild -bb "$topdir/SPECS/hex.spec" --define "_topdir $topdir"

built=$(find "$topdir/RPMS" -name 'hex-*.rpm' -print -quit)
if [ -z "$built" ]; then
  echo "rpmbuild produced no package." >&2
  exit 1
fi

install -m0644 "$built" "$out/hex.x86_64.rpm"
echo "==> Wrote $out/hex.x86_64.rpm"
rpm -qp --qf 'name=%{NAME} version=%{VERSION}-%{RELEASE} arch=%{ARCH}\n' "$out/hex.x86_64.rpm"
