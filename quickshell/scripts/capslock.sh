#!/usr/bin/env bash
# Real-time Caps Lock state monitor for Quickshell
set -u

check_caps() {
    if grep -sq '1' /sys/class/leds/*capslock/brightness 2>/dev/null; then
        echo "1"
    elif hyprctl devices -j 2>/dev/null | grep -q '"capsLock": true'; then
        echo "1"
    else
        echo "0"
    fi
}

prev_state=""
while true; do
    curr_state="$(check_caps)"
    if [[ "$curr_state" != "$prev_state" ]]; then
        echo "$curr_state"
        prev_state="$curr_state"
    fi
    sleep 0.1
done
