#!/bin/bash
TYPE=$1

# Identify what is currently running
CURRENT=""
if pgrep -f "rofimoji" >/dev/null; then
    CURRENT="emoji"
elif pgrep -x "rofi" >/dev/null; then
    CURRENT="drun"
fi

# Kill any existing rofi instances
pkill -x rofi
pkill -f rofimoji

# If the user pressed the hotkey for the menu that is ALREADY open,
# we just wanted to toggle it off, so we exit now.
if [ "$CURRENT" = "$TYPE" ]; then
    exit 0
fi

# Otherwise, open the newly requested menu
if [ "$TYPE" = "drun" ]; then
    rofi -show drun
elif [ "$TYPE" = "emoji" ]; then
    rofimoji --action clipboard --hidden-descriptions --selector-args "-theme ~/.config/rofi/rofimoji-theme.rasi"
fi
