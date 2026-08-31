#!/bin/bash
# Power Profile & TLP Optimizer Controller
# Manages system TLP profiles and desktop shell performance modes.

STATE_DIR="$HOME/.config/quickshell/state"
STATE_FILE="$STATE_DIR/power_profile.txt"
mkdir -p "$STATE_DIR"

notify() {
    local text="$1"
    local color="$2"
    hyprctl repl "hl.notification.create({ text = '$text', time = 2000, color = '$color' })" > /dev/null 2>&1 || true
}

apply_profile() {
    local mode="$1"
    case "$mode" in
        performance)
            echo "performance" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = false } })" > /dev/null 2>&1 || true
            sudo -n tlp ac > /dev/null 2>&1 || tlp ac > /dev/null 2>&1 || true
            notify "󰓅  Power Profile: Performance (Max Speed & Animations)" "rgba(122, 162, 247, 1.0)"
            ;;
        balanced)
            echo "balanced" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = true, dim_strength = 0.15 } })" > /dev/null 2>&1 || true
            sudo -n tlp auto > /dev/null 2>&1 || tlp auto > /dev/null 2>&1 || true
            notify "󰾆  Power Profile: Balanced (Standard Fluid Dynamic)" "rgba(57, 197, 187, 1.0)"
            ;;
        powersave)
            echo "powersave" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = false }, decoration = { dim_inactive = true, dim_strength = 0.25 } })" > /dev/null 2>&1 || true
            sudo -n tlp bat > /dev/null 2>&1 || tlp bat > /dev/null 2>&1 || true
            notify "󰌪  Power Profile: Power Saver (Low Power & Animations Off)" "rgba(158, 206, 106, 1.0)"
            ;;
        *)
            echo "Usage: $0 {set [performance|balanced|powersave]|cycle|get|restore}"
            exit 1
            ;;
    esac
}

get_profile() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "balanced"
    fi
}

case "$1" in
    set)
        apply_profile "$2"
        ;;
    cycle)
        current=$(get_profile)
        case "$current" in
            performance)
                apply_profile "balanced"
                ;;
            balanced)
                apply_profile "powersave"
                ;;
            powersave|*)
                apply_profile "performance"
                ;;
        esac
        ;;
    get)
        get_profile
        ;;
    restore)
        current=$(get_profile)
        apply_profile "$current"
        ;;
    *)
        echo "Usage: $0 {set [performance|balanced|powersave]|cycle|get|restore}"
        exit 1
        ;;
esac
