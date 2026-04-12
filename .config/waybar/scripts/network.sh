#!/bin/bash

# Get primary interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

if [[ -z "$INTERFACE" ]]; then
    echo '{"text": "[ NET -- ]", "tooltip": "No network"}'
    exit 0
fi

# Read bytes
RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

# Calculate KB/s
RX_KB=$(( (RX2 - RX1) / 1024 ))
TX_KB=$(( (TX2 - TX1) / 1024 ))

# Format
if [[ $RX_KB -ge 1024 ]]; then
    RX_FMT="$(awk "BEGIN {printf \"%.1f\", $RX_KB/1024}")M"
else
    RX_FMT="${RX_KB}K"
fi

if [[ $TX_KB -ge 1024 ]]; then
    TX_FMT="$(awk "BEGIN {printf \"%.1f\", $TX_KB/1024}")M"
else
    TX_FMT="${TX_KB}K"
fi

echo "{\"text\": \"[ ${TX_FMT} ${RX_FMT} ]\", \"tooltip\": \"Interface: $INTERFACE\\nUp: ${TX_FMT}/s\\nDown: ${RX_FMT}/s\"}"
