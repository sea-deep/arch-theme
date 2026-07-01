#!/bin/bash
if swaymsg -t get_tree | grep -q '"app_id": "clipse"'; then
    swaymsg '[app_id="clipse"] kill'
else
    kitty --class clipse -o hide_window_decorations=no -o window_margin_width=4 -e clipse
fi
