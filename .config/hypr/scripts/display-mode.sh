#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
STATE_FILE="$STATE_DIR/display-mode"
mkdir -p "$STATE_DIR"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "Display mode" "$1" "$2" || true
}

write_state() {
  printf '%s
' "$1" > "$STATE_FILE"
}

current_state() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    echo desk
  fi
}

secondary_dp() {
  hyprctl -j monitors all 2>/dev/null | jq -r '.[] | .name' | grep -E '^DP-[23]$' | head -n1 || true
}

connected() {
  local name=$1
  hyprctl -j monitors all 2>/dev/null | jq -e --arg n "$name" '.[] | select(.name == $n)' >/dev/null 2>&1
}

apply_kw() {
  hyprctl keyword monitor "$1" >/dev/null
}

disable_if_present() {
  local name=$1
  connected "$name" && apply_kw "$name,disable" || true
}

apply_mode() {
  local mode=$1
  local second
  second=$(secondary_dp)

  case "$mode" in
    desk)
      apply_kw "DP-1,2560x1440@90,0x0,auto,bitdepth,12,vrr,1"
      disable_if_present DP-2
      disable_if_present DP-3
      disable_if_present HDMI-A-1
      ;;
    desk-165)
      apply_kw "DP-1,2560x1440@165,0x0,auto,bitdepth,12,vrr,1"
      disable_if_present DP-2
      disable_if_present DP-3
      disable_if_present HDMI-A-1
      ;;
    dual)
      apply_kw "DP-1,2560x1440@90,0x0,auto,bitdepth,12,vrr,1"
      disable_if_present HDMI-A-1
      if [[ -n "$second" ]]; then
        apply_kw "$second,1920x1080@144,2560x0,auto,bitdepth,12,vrr,1"
      fi
      ;;
    tv-extend)
      apply_kw "DP-1,2560x1440@90,0x0,auto,bitdepth,12,vrr,1"
      disable_if_present DP-2
      disable_if_present DP-3
      apply_kw "HDMI-A-1,3840x2160@60,2560x0,auto,bitdepth,10"
      ;;
    tv-mirror)
      apply_kw "DP-1,1920x1080@120,0x0,auto,bitdepth,12,vrr,1"
      disable_if_present DP-2
      disable_if_present DP-3
      apply_kw "HDMI-A-1,1920x1080@120,auto,auto,bitdepth,10,mirror,DP-1"
      ;;
    *)
      echo "unknown mode: $mode" >&2
      exit 1
      ;;
  esac

  write_state "$mode"
  notify "Display profile applied" "$mode"
}

waybar_json() {
  local mode outputs tooltip text class
  mode=$(current_state)
  outputs=$(hyprctl -j monitors 2>/dev/null | jq -r '[.[].name] | join(", ")' 2>/dev/null || echo "unknown")
  text="[ ${mode} ]"
  tooltip="Left click: choose display profile
Right click: cycle profile
Active outputs: ${outputs}"
  class=$(printf '%s' "$mode" | tr -c '[:alnum:]' '-')
  jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" '{text:$text, tooltip:$tooltip, class:$class}'
}

menu() {
  local choice
  choice=$(printf '%s
'     "desk"     "desk-165"     "dual"     "tv-extend"     "tv-mirror" | wofi --show dmenu --prompt "display" --width 260 --height 320 --cache-file /dev/null)
  [[ -n "${choice:-}" ]] && apply_mode "$choice"
}

next_mode() {
  local current next
  current=$(current_state)
  case "$current" in
    desk) next=desk-165 ;;
    desk-165) next=dual ;;
    dual) next=tv-extend ;;
    tv-extend) next=tv-mirror ;;
    *) next=desk ;;
  esac
  apply_mode "$next"
}

case "${1:-waybar}" in
  waybar|current) waybar_json ;;
  menu) menu ;;
  next) next_mode ;;
  apply) apply_mode "${2:?missing mode}" ;;
  *)
    echo "usage: $0 {waybar|current|menu|next|apply <mode>}" >&2
    exit 1
    ;;
esac
