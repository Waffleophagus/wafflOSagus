#!/usr/bin/env bash
set -oue pipefail

RELEASE_URL=$(curl -s https://api.github.com/repos/peteonrails/voxtype/releases/latest \
  | grep "browser_download_url.*\.rpm" \
  | cut -d '"' -f 4 \
  | head -n 1)

rpm-ostree install "$RELEASE_URL"
