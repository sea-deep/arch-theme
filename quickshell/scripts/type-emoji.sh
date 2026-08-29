#!/bin/bash
CHAR="$1"
# Wait for Quickshell popup to fully close and focus to return
sleep 0.15
# Try typing directly into the focused window
if wtype "$CHAR" 2>/dev/null; then
    exit 0
fi
# Fallback: copy to clipboard
wl-copy "$CHAR"
notify-send -a "Emoji" -t 1500 "📋 Copied $CHAR"
