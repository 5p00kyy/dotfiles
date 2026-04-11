#!/usr/bin/env bash
set -euo pipefail
count=$(checkupdates 2>/dev/null | wc -l)
class="ok"
if (( count > 40 )); then
  class="warn"
fi
text="[ UPD ${count} ]"
tooltip="Pending pacman updates: ${count}"
jq -cn --arg text "$text" --arg class "$class" --arg tooltip "$tooltip" '{text:$text,class:$class,tooltip:$tooltip}'
