#!/bin/bash
hyprctl reload
killall qs || true
sleep 0.5
QT_LOGGING_RULES="quickshell.network.warning=false" /usr/bin/qs --no-duplicate > /dev/null 2>&1 &
