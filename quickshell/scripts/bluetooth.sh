#!/bin/bash
# Bluetooth Power & Persistence Controller
# Manages system Bluetooth power state and session persistence.
set -euo pipefail

STATE_DIR="$HOME/.config/quickshell/state"
STATE_FILE="$STATE_DIR/bluetooth.txt"
mkdir -p "$STATE_DIR"

case "${1:-get}" in
    set)
        state="${2:-off}"
        if [[ "$state" == "on" ]]; then
            bluetoothctl power on >/dev/null 2>&1 || true
            rfkill unblock bluetooth >/dev/null 2>&1 || true
            echo "on" > "$STATE_FILE"
        else
            bluetoothctl power off >/dev/null 2>&1 || true
            rfkill block bluetooth >/dev/null 2>&1 || true
            echo "off" > "$STATE_FILE"
        fi
        ;;
    toggle)
        cur="$(cat "$STATE_FILE" 2>/dev/null || echo "off")"
        if [[ "$cur" == "on" ]]; then
            "$0" set off
        else
            "$0" set on
        fi
        ;;
    get)
        if [[ -f "$STATE_FILE" ]]; then
            cat "$STATE_FILE"
        else
            if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
                echo "on"
            else
                echo "off"
            fi
        fi
        ;;
    restore)
        if [[ -f "$STATE_FILE" ]]; then
            saved="$(cat "$STATE_FILE" 2>/dev/null || echo "off")"
            if [[ "$saved" == "on" ]]; then
                bluetoothctl power on >/dev/null 2>&1 || true
                rfkill unblock bluetooth >/dev/null 2>&1 || true
            else
                bluetoothctl power off >/dev/null 2>&1 || true
                rfkill block bluetooth >/dev/null 2>&1 || true
            fi
        else
            bluetoothctl power off >/dev/null 2>&1 || true
            rfkill block bluetooth >/dev/null 2>&1 || true
            echo "off" > "$STATE_FILE"
        fi
        ;;
    *)
        echo "Usage: $0 {set [on|off]|toggle|get|restore}"
        exit 1
        ;;
esac
