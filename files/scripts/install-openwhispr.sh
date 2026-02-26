#!/usr/bin/env bash
set -oue pipefail

rpm-ostree install https://github.com/OpenWhispr/openwhispr/releases/download/v1.5.4/OpenWhispr-1.5.4-linux-x86_64.rpm
