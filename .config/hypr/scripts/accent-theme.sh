#!/usr/bin/env bash
set -euo pipefail
THEME_DIR="$HOME/.config/theme"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
STATE_FILE="$STATE_DIR/accent-theme"
mkdir -p "$STATE_DIR"
current(){ [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo green; }
write_state(){ printf '%s\n' "$1" > "$STATE_FILE"; }
apply_links(){ ln -sfn "accent-$1.css" "$THEME_DIR/current-accent.css"; }
apply_hypr(){
  local t=$1
  command -v hyprctl >/dev/null 2>&1 || return 0
  if [[ "$t" == green ]]; then
    hyprctl keyword general:col.active_border "rgb(3fb950)" >/dev/null 2>&1 || true
    hyprctl keyword group:groupbar:col.active "rgb(3fb950) rgb(161b22) 90deg" >/dev/null 2>&1 || true
  else
    hyprctl keyword general:col.active_border "rgb(9b5cff)" >/dev/null 2>&1 || true
    hyprctl keyword group:groupbar:col.active "rgb(9b5cff) rgb(161b22) 90deg" >/dev/null 2>&1 || true
  fi
}
reload_ui(){ pkill -USR2 waybar 2>/dev/null || true; command -v swaync-client >/dev/null 2>&1 && swaync-client --reload-config >/dev/null 2>&1 || true; }
notify(){ command -v notify-send >/dev/null 2>&1 && notify-send -a Theme "Accent switched" "$1" || true; }
waybar_json(){
  local t text class
  t=$(current)
  if [[ "$t" == green ]]; then text='[ ACC GRN ]'; class='accent-green'; else text='[ ACC PUR ]'; class='accent-purple'; fi
  jq -cn --arg text "$text" --arg class "$class" --arg tooltip "Left click: toggle accent\nCurrent accent: $t" '{text:$text,class:$class,tooltip:$tooltip}'
}
apply(){ [[ "${1:-}" =~ ^(purple|green)$ ]] || { echo invalid theme >&2; exit 1; }; apply_links "$1"; write_state "$1"; apply_hypr "$1"; reload_ui; notify "$1"; }
cycle(){ [[ "$(current)" == purple ]] && apply green || apply purple; }
case "${1:-waybar}" in
  waybar|current) waybar_json ;;
  toggle|next) cycle ;;
  apply) apply "${2:?missing theme}" ;;
  *) echo "usage: $0 {waybar|current|toggle|next|apply <purple|green>}" >&2; exit 1 ;;
esac
