#!/bin/bash

# Check if rofi is already running
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

# Options with dmenu icon syntax: Label\0icon\x1ficon-name
shutdown="Shutdown\0icon\x1fsystem-shutdown"
reboot="Reboot\0icon\x1fsystem-reboot"
suspend="Suspend\0icon\x1fsystem-suspend"
logout="Logout\0icon\x1fsystem-log-out"
lock="Lock\0icon\x1fsystem-lock-screen"

options="$shutdown\n$reboot\n$suspend\n$logout\n$lock"

# The chosen variable will only contain the text before \0
chosen="$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -show-icons -theme ~/.config/rofi/powermenu.rasi)"

case $chosen in
    Shutdown)
        systemctl poweroff
        ;;
    Reboot)
        systemctl reboot
        ;;
    Suspend)
        systemctl suspend
        ;;
    Logout)
        hyprctl dispatch exit
        ;;
    Lock)
        hyprlock
        ;;
esac
