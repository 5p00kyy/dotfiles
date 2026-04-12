#!/usr/bin/env bash
set -euo pipefail
pkill wofi 2>/dev/null || true
wofi --show drun --prompt "run" --width 900 --height 520 --normal-window --hide-scroll --style "$HOME/.config/wofi/style.css"
