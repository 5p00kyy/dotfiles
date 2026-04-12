#!/usr/bin/env bash
set -euo pipefail
if pgrep -x hypridle >/dev/null 2>&1; then
  jq -cn '{text:"idle on",class:"active",tooltip:"Idle daemon active. Click to lock now."}'
else
  jq -cn '{text:"idle off",class:"inactive",tooltip:"Idle daemon not running. Click to lock now."}'
fi
