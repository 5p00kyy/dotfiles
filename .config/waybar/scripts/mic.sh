#!/usr/bin/env bash
set -euo pipefail
if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q 'yes'; then
  jq -cn '{text:"[ mic off ]",class:"warn",tooltip:"Microphone muted"}'
else
  jq -cn '{text:"[ mic on ]",class:"ok",tooltip:"Microphone active"}'
fi
