#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
STATE_FILE="$STATE_DIR/network.state"
mkdir -p "$STATE_DIR"
iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
if [[ -z "${iface:-}" || ! -d "/sys/class/net/$iface" ]]; then
  jq -cn --arg text "[ NET down ]" --arg class "crit" --arg tooltip "No default route" '{text:$text,class:$class,tooltip:$tooltip}'
  exit 0
fi
rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
now=$(date +%s)
ip4=$(ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet / {print $2; exit}')
gw=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
vpn=$(nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | awk -F: '$1=="vpn" {print $2; exit}')
ping_ms=$(ping -n -q -c 1 -W 1 1.1.1.1 2>/dev/null | awk -F'/' 'END{if (NF>=5) printf "%d", $5}')
rx_rate=0
tx_rate=0
if [[ -f "$STATE_FILE" ]]; then
  read -r prev_now prev_rx prev_tx < "$STATE_FILE" || true
  if [[ -n "${prev_now:-}" && "$now" -gt "$prev_now" ]]; then
    dt=$((now - prev_now))
    rx_rate=$(((rx - prev_rx) / dt / 1024))
    tx_rate=$(((tx - prev_tx) / dt / 1024))
  fi
fi
printf '%s %s %s\n' "$now" "$rx" "$tx" > "$STATE_FILE"
lat="--"
class="ok"
if [[ -n "${ping_ms:-}" ]]; then
  lat="${ping_ms}ms"
  if (( ping_ms >= 120 )); then class="warn"; fi
else
  class="warn"
fi
vpn_tag=""
[[ -n "${vpn:-}" ]] && vpn_tag=" VPN"
text="[ NET ${iface}${vpn_tag} ↓${rx_rate} ↑${tx_rate} ${lat} ]"
tooltip="IP: ${ip4:-unknown}\nGateway: ${gw:-unknown}\nVPN: ${vpn:-off}\nRates: down ${rx_rate} KiB/s, up ${tx_rate} KiB/s"
jq -cn --arg text "$text" --arg class "$class" --arg tooltip "$tooltip" '{text:$text,class:$class,tooltip:$tooltip}'
