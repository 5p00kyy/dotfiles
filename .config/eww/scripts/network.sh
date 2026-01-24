#!/bin/bash

# Get primary network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

if [[ -z "$INTERFACE" ]]; then
    echo "N/A"
    exit 0
fi

# Read current bytes
RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)

sleep 1

# Read bytes again
RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)

# Calculate speed
RX_SPEED=$((RX2 - RX1))
TX_SPEED=$((TX2 - TX1))

# Format output
format_speed() {
    local bytes=$1
    if [[ $bytes -ge 1048576 ]]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}") MB/s"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}") KB/s"
    else
        echo "${bytes} B/s"
    fi
}

case "$1" in
    up)
        format_speed $TX_SPEED
        ;;
    down)
        format_speed $RX_SPEED
        ;;
    *)
        echo "Usage: $0 {up|down}"
        ;;
esac
