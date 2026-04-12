#!/bin/bash

# AMD GPU stats from sysfs
TEMP=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null)
USAGE=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null)

if [[ -n "$TEMP" ]]; then
    TEMP_C=$((TEMP / 1000))
    echo "[ GPU ${TEMP_C}C ${USAGE}% ]"
else
    echo "[ GPU N/A ]"
fi
