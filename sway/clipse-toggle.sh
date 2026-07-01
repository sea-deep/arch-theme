#!/bin/bash
if swaymsg -t get_tree | grep -q '"app_id": "clipse"'; then
    swaymsg '[app_id="clipse"] kill'
else
    kitty --class clipse -o window_margin_width=4 -o window_border_width=2 -o draw_window_borders_for_single_window=yes -o active_border_color="#39c5bb" -o inactive_border_color="#39c5bb" -e clipse
fi
