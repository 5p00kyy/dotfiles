#!/usr/bin/env bash
set -euo pipefail
if hyprctl -j clients 2>/dev/null | jq -e '.[] | select(.class == "ops-dashboard")' >/dev/null 2>&1; then
  hyprctl dispatch focuswindow 'class:^(ops-dashboard)$' >/dev/null 2>&1 || true
  exit 0
fi
kitty --class ops-dashboard --title OPS-DASHBOARD bash -lc '~/.config/hypr/scripts/ops-dashboard-view.sh' >/dev/null 2>&1 & disown
