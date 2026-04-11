#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
STATE_FILE="$STATE_DIR/cpu.state"
mkdir -p "$STATE_DIR"
read -r _ u n s i w irq sirq st _ < /proc/stat
total=$((u+n+s+i+w+irq+sirq+st))
idle=$((i+w))
cpu=0
if [[ -f "$STATE_FILE" ]]; then
  read -r prev_total prev_idle < "$STATE_FILE" || true
  if [[ -n "${prev_total:-}" && "$total" -gt "$prev_total" ]]; then
    diff_total=$((total - prev_total))
    diff_idle=$((idle - prev_idle))
    cpu=$(((100 * (diff_total - diff_idle)) / diff_total))
  fi
fi
printf '%s %s\n' "$total" "$idle" > "$STATE_FILE"
mem=$(free | awk '/Mem:/ {printf "%d", ($3/$2)*100}')
gpu_json=$(amdgpu_top -J -n 1 2>/dev/null || true)
gpu_use=$(jq -r '.devices[0].gpu_activity.GFX.value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
gpu_temp=$(jq -r '.devices[0].Sensors["Edge Temperature"].value // .devices[0].Sensors["Junction Temperature"].value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
vram_used=$(jq -r '.devices[0].VRAM["Total VRAM Usage"].value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
vram_total=$(jq -r '.devices[0].VRAM["Total VRAM"].value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
class="ok"
if (( cpu >= 85 || mem >= 85 || gpu_temp >= 85 )); then
  class="crit"
elif (( cpu >= 65 || mem >= 70 || gpu_temp >= 75 )); then
  class="warn"
fi
text="[ SYS C${cpu}% M${mem}% G${gpu_use}% ${gpu_temp}C ]"
tooltip="CPU: ${cpu}%\nMemory: ${mem}%\nGPU: ${gpu_use}%\nGPU Temp: ${gpu_temp}C\nVRAM: ${vram_used}/${vram_total} MiB"
jq -cn --arg text "$text" --arg class "$class" --arg tooltip "$tooltip" '{text:$text,class:$class,tooltip:$tooltip}'
