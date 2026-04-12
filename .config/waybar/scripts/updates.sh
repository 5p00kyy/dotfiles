#!/usr/bin/env bash
set -euo pipefail
if command -v checkupdates >/dev/null 2>&1; then
  count=$(checkupdates 2>/dev/null | wc -l)
  if (( count > 0 )); then
    jq -cn --arg text "upd ${count}" --arg class "has-updates" --arg tooltip "Pending pacman updates: ${count}" '{text:$text,class:$class,tooltip:$tooltip}'
  else
    jq -cn --arg text "upd 0" --arg class "" --arg tooltip "System is up to date" '{text:$text,class:$class,tooltip:$tooltip}'
  fi
else
  jq -cn --arg text "upd n/a" --arg class "" --arg tooltip "checkupdates not available" '{text:$text,class:$class,tooltip:$tooltip}'
fi
