#!/usr/bin/env bash
set -euo pipefail
iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
if [[ -z "${iface:-}" ]]; then
  jq -cn '{text:"[ net down ]",class:"crit",tooltip:"No default route"}'
  exit 0
fi
ping_ms=$(ping -n -q -c 1 -W 1 1.1.1.1 2>/dev/null | awk -F'/' 'END{if (NF>=5) printf "%d", $5}')
class="ok"
lat="--"
if [[ -n "${ping_ms:-}" ]]; then
  lat="${ping_ms}ms"
  if (( ping_ms >= 120 )); then class="warn"; fi
else
  class="warn"
fi
ip4=$(ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet / {print $2; exit}')
jq -cn --arg text "[ ${iface} ${lat} ]" --arg class "$class" --arg tooltip "Interface: ${iface}\nIP: ${ip4:-unknown}\nLatency: ${lat}" '{text:$text,class:$class,tooltip:$tooltip}'
