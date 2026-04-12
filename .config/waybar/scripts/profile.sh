#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
accent="green"
profile="desk"
[[ -f "$STATE_DIR/accent-theme" ]] && accent=$(tr -d '\n' < "$STATE_DIR/accent-theme")
[[ -f "$STATE_DIR/display-mode" ]] && profile=$(tr -d '\n' < "$STATE_DIR/display-mode")
idle="OFF"
pgrep -x hypridle >/dev/null 2>&1 && idle="ON"
acc_label="GRN"
[[ "$accent" == "purple" ]] && acc_label="PUR"
class="ok"
[[ "$idle" == "OFF" ]] && class="warn"
text="[ OPS $profile $acc_label IDLE:$idle ]"
tooltip="Left click: open ops dashboard\nMiddle click: display profile chooser\nRight click: toggle accent"
jq -cn --arg text "$text" --arg class "$class" --arg tooltip "$tooltip" '{text:$text,class:$class,tooltip:$tooltip}'
