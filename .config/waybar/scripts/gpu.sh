#!/usr/bin/env bash
set -euo pipefail
class="ok"
if command -v amdgpu_top >/dev/null 2>&1; then
  gpu_json=$(amdgpu_top -J -n 1 2>/dev/null || true)
  gpu_use=$(jq -r '.devices[0].gpu_activity.GFX.value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
  gpu_temp=$(jq -r '.devices[0].Sensors["Edge Temperature"].value // .devices[0].Sensors["Junction Temperature"].value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
  gpu_name=$(jq -r '.devices[0].Info.DeviceName // "AMD GPU"' <<<"$gpu_json" 2>/dev/null || echo "AMD GPU")
  vram_used=$(jq -r '.devices[0].VRAM["Total VRAM Usage"].value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
  vram_total=$(jq -r '.devices[0].VRAM["Total VRAM"].value // 0' <<<"$gpu_json" 2>/dev/null || echo 0)
  if (( gpu_temp >= 85 )); then
    class="crit"
  elif (( gpu_temp >= 75 )); then
    class="warn"
  fi
  jq -cn --arg text "gpu ${gpu_temp}c ${gpu_use}%" --arg class "$class" --arg tooltip "${gpu_name}\nGPU temp: ${gpu_temp}C\nGPU usage: ${gpu_use}%\nVRAM: ${vram_used}/${vram_total} MiB" '{text:$text,class:$class,tooltip:$tooltip}'
  exit 0
fi
jq -cn --arg text "gpu n/a" --arg class "warn" --arg tooltip "amdgpu_top not available" '{text:$text,class:$class,tooltip:$tooltip}'
