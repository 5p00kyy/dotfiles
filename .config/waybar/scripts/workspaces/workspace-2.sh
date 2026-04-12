#!/usr/bin/env bash
set -euo pipefail
active=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 0' 2>/dev/null || echo 0)
if [ "$active" = "2" ]; then
  jq -cn --arg text "●" --arg class "active" --arg tooltip "Workspace 2" '{text:$text,class:$class,tooltip:$tooltip}'
else
  jq -cn --arg text "2" --arg class "inactive" --arg tooltip "Workspace 2" '{text:$text,class:$class,tooltip:$tooltip}'
fi
