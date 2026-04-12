#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
while true; do
  clear
  accent="green"; [[ -f "$STATE_DIR/accent-theme" ]] && accent=$(tr -d '\n' < "$STATE_DIR/accent-theme")
  profile="desk"; [[ -f "$STATE_DIR/display-mode" ]] && profile=$(tr -d '\n' < "$STATE_DIR/display-mode")
  default_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
  ip4=$(ip -4 addr show dev "$default_iface" 2>/dev/null | awk '/inet / {print $2; exit}')
  gw=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
  ping_ms=$(ping -n -q -c 1 -W 1 1.1.1.1 2>/dev/null | awk -F'/' 'END{if (NF>=5) printf "%d", $5; else print "--"}')
  mem_line=$(free -h | awk '/Mem:/ {printf "%-8s / %-8s (%d%%)", $3, $2, ($3/$2)*100}' 2>/dev/null || true)
  root_line=$(df -h / | awk 'NR==2 {printf "%s used / %s total (%s)", $3, $2, $5}')
  load_line=$(awk '{printf "%s %s %s", $1, $2, $3}' /proc/loadavg)
  gpu_name="AMD GPU"
  gpu_use="--"
  gpu_temp="--"
  vram_used="--"
  vram_total="--"
  if command -v amdgpu_top >/dev/null 2>&1; then
    gpu_json=$(amdgpu_top -J -n 1 2>/dev/null || true)
    gpu_name=$(jq -r '.devices[0].Info.DeviceName // "AMD GPU"' <<<"$gpu_json" 2>/dev/null || echo "AMD GPU")
    gpu_use=$(jq -r '.devices[0].gpu_activity.GFX.value // "--"' <<<"$gpu_json" 2>/dev/null || echo "--")
    gpu_temp=$(jq -r '.devices[0].Sensors["Edge Temperature"].value // .devices[0].Sensors["Junction Temperature"].value // "--"' <<<"$gpu_json" 2>/dev/null || echo "--")
    vram_used=$(jq -r '.devices[0].VRAM["Total VRAM Usage"].value // "--"' <<<"$gpu_json" 2>/dev/null || echo "--")
    vram_total=$(jq -r '.devices[0].VRAM["Total VRAM"].value // "--"' <<<"$gpu_json" 2>/dev/null || echo "--")
  fi
  if command -v checkupdates >/dev/null 2>&1; then
    updates=$(checkupdates 2>/dev/null | wc -l)
  else
    updates="n/a"
  fi
  idle_state="off"; pgrep -x hypridle >/dev/null 2>&1 && idle_state="on"
  printf '\n[ OPS DASHBOARD ]  %s\n\n' "$(date '+%a %d %b %Y  %H:%M:%S')"
  printf '  profile      %s\n' "$profile"
  printf '  accent       %s\n' "$accent"
  printf '  hypridle     %s\n' "$idle_state"
  printf '  load         %s\n' "$load_line"
  printf '  memory       %s\n' "$mem_line"
  printf '  root         %s\n' "$root_line"
  printf '  gpu          %s | use %s%% | temp %sC | vram %s/%s MiB\n' "$gpu_name" "$gpu_use" "$gpu_temp" "$vram_used" "$vram_total"
  printf '  network      %s | %s | gw %s | ping %sms\n' "${default_iface:---}" "${ip4:---}" "${gw:---}" "$ping_ms"
  printf '  updates      %s\n\n' "$updates"
  printf '  actions      [ q ] quit    [ d ] display menu    [ a ] accent toggle    [ r ] reload waybar\n\n'
  printf '  top cpu\n'
  ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 8
  printf '\n  top memory\n'
  ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 8
  read -r -t 2 -n 1 key || true
  case "${key:-}" in
    q) exit 0 ;;
    d) ~/.config/hypr/scripts/display-mode.sh menu >/dev/null 2>&1 ;;
    a) ~/.config/hypr/scripts/accent-theme.sh toggle >/dev/null 2>&1 ;;
    r) pkill -USR2 waybar >/dev/null 2>&1 || true ;;
  esac
  unset key
done
