#!/bin/bash
hyprctl reload
killall qs quickshell 2>/dev/null || true
sleep 0.3
QT_LOGGING_RULES="quickshell.network.warning=false" qs --no-duplicate > /dev/null 2>&1 &
"$HOME/.config/quickshell/scripts/update_shader.sh" > /dev/null 2>&1 &
