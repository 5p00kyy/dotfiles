#!/bin/bash

pkill wofi 2>/dev/null

chosen=$(cat <<EOF | wofi --show dmenu --prompt "" --width 200 --height 300 --cache-file /dev/null --hide-search --conf /dev/null --style ~/.config/wofi/power-menu.css
  Shutdown
  Reboot
  Suspend
  Logout
  Lock
EOF
)

case "$chosen" in
    *Shutdown) systemctl poweroff ;;
    *Reboot) systemctl reboot ;;
    *Suspend) systemctl suspend ;;
    *Logout) hyprctl dispatch exit ;;
    *Lock) hyprlock || swaylock ;;
esac
