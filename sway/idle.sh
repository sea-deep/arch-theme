#!/bin/bash
# Kill any existing swayidle instance to ensure we only have one running
pkill -x swayidle

swayidle -w \
         timeout 60 'brightnessctl -s set 10' resume 'brightnessctl -r' \
         timeout 120 'swaylock -f' \
         timeout 300 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
         timeout 600 'systemctl suspend' \
         before-sleep 'swaylock -f'
