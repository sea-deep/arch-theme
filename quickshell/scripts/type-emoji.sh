#!/bin/bash
CHAR="$1"
# Wait a tiny bit for the Quickshell popup to close and focus to return to the app
sleep 0.1
if ! wtype "$CHAR" 2>/dev/null; then
    wl-copy "$CHAR"
    notify-send -a "Quickshell" -t 1500 "Copied $CHAR to clipboard"
fi
