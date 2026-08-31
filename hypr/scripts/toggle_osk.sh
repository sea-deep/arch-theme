#!/bin/bash
# Toggle wvkbd lightweight on-screen virtual keyboard with TokyoNight palette

if pgrep -x "wvkbd-mobintl" > /dev/null || pgrep -x "wvkbd-deskintl" > /dev/null || pgrep -x "wvkbd" > /dev/null; then
    pkill -x "wvkbd-mobintl" 2>/dev/null || true
    pkill -x "wvkbd-deskintl" 2>/dev/null || true
    pkill -x "wvkbd" 2>/dev/null || true
else
    "$HOME/.local/bin/wvkbd-mobintl" \
        -L 280 \
        -R 8 \
        --bg 1a1b26 \
        --fg 24283b \
        --fg-sp 1f2335 \
        --press 39c5bb \
        --press-sp 39c5bb \
        --text c0caf5 \
        --text-sp 7aa2f7 \
        --text-press 1a1b26 \
        --fn "IBM Plex Sans 12" \
        > /dev/null 2>&1 &
fi
