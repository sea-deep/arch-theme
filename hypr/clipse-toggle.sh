#!/bin/bash
# ── Section ──
# Clipse Toggler
if hyprctl clients -j | jq -e '.[] | select(.class == "clipse")' > /dev/null 2>&1; then
    hyprctl dispatch closewindow class:clipse
else
    kitty --class clipse -o hide_window_decorations=no -o window_margin_width=4 -e clipse
fi
