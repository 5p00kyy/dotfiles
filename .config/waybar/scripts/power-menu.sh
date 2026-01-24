#!/bin/bash

options="  Shutdown\n  Reboot\n  Logout\n  Lock"

chosen=$(echo -e "$options" | wofi --dmenu --prompt "Power" --width 200 --height 180 --cache-file /dev/null)

case "$chosen" in
    *Shutdown) systemctl poweroff ;;
    *Reboot) systemctl reboot ;;
    *Logout) hyprctl dispatch exit ;;
    *Lock) hyprlock || swaylock ;;
esac
