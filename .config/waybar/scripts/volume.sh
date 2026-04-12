#!/usr/bin/env bash
set -euo pipefail
vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{ print $2 }')
vol_int=$(awk -v v="$vol_raw" 'BEGIN { printf "%d", v * 100 }')
is_muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo true || echo false)
sink=$(wpctl status | awk '/Sinks:/,/Sources:/' | grep '\*' | cut -d'.' -f2- | sed 's/^\s*//; s/\[.*//')
class="ok"
if [ "$is_muted" = true ]; then
  class="warn"
  vol_int=0
fi
jq -cn --arg text "[ vol ${vol_int}% ]" --arg class "$class" --arg tooltip "Audio: ${vol_int}%\nOutput: ${sink}" '{text:$text,class:$class,tooltip:$tooltip}'
