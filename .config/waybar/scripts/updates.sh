#!/usr/bin/env bash
set -euo pipefail
if command -v checkupdates >/dev/null 2>&1; then
  count=$(checkupdates 2>/dev/null | wc -l)
  class="ok"
  if (( count > 40 )); then
    class="warn"
  fi
  text="[ UPD ${count} ]"
  tooltip="Pending pacman updates: ${count}"
else
  class="warn"
  text="[ UPD n/a ]"
  tooltip="checkupdates not available"
fi
jq -cn --arg text "$text" --arg class "$class" --arg tooltip "$tooltip" '{text:$text,class:$class,tooltip:$tooltip}'
