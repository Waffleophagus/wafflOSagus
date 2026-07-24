#!/usr/bin/env bash
set -euo pipefail
# Bake the default desktop user into the 'input' group in the image's vendor
# group file (/usr/lib/group, read via nsswitch 'altfiles'). Fresh login
# sessions then resolve 'input' membership from the image, so apps needing
# /dev/input/event* (e.g. OpenWhispr) work with no runtime gpasswd/usermod step.
GROUP_FILE=/usr/lib/group
USER_NAME=matt
grep -q '^input:' "$GROUP_FILE" || echo 'input:x:104:' >> "$GROUP_FILE"
if ! grep -qE "^input:x:104:([^:]*,)?${USER_NAME}(,[^:]*)?$" "$GROUP_FILE"; then
  if grep -q '^input:x:104:$' "$GROUP_FILE"; then
    sed -i "s/^input:x:104:\$/input:x:104:${USER_NAME}/" "$GROUP_FILE"
  else
    sed -i -E "s/^(input:x:104:[^:]*)\$/\\1,${USER_NAME}/" "$GROUP_FILE"
  fi
fi
