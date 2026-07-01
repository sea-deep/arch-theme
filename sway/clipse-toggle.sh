#!/bin/bash
if swaymsg -t get_tree | grep -q '"app_id": "clipse"'; then
    swaymsg '[app_id="clipse"] kill'
else
    kitty --class clipse -o window_margin_width=4 -e clipse
fi
