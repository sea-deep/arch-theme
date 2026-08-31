#!/bin/bash
# Power Profile & TLP Optimizer Controller
# Manages system TLP profiles and desktop shell performance modes.

STATE_DIR="$HOME/.config/quickshell/state"
STATE_FILE="$STATE_DIR/power_profile.txt"
mkdir -p "$STATE_DIR"

notify() {
    local summary="$1"
    local body="$2"
    local icon="$3"
    notify-send -a "Power Management" -i "$icon" "$summary" "$body" > /dev/null 2>&1 || true
}

apply_profile() {
    local mode="$1"
    case "$mode" in
        performance)
            echo "performance" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = false } })" > /dev/null 2>&1 || true
            sudo -n tlp ac > /dev/null 2>&1 || tlp ac > /dev/null 2>&1 || true
            notify "Performance Mode" "Maximum CPU frequency and fluid animations enabled." "battery-charging"
            ;;
        balanced)
            echo "balanced" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = true, dim_strength = 0.15 } })" > /dev/null 2>&1 || true
            sudo -n tlp auto > /dev/null 2>&1 || tlp auto > /dev/null 2>&1 || true
            notify "Balanced Mode" "Dynamic CPU scaling and standard fluid animations." "battery-good"
            ;;
        powersave)
            echo "powersave" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = false }, decoration = { dim_inactive = true, dim_strength = 0.25 } })" > /dev/null 2>&1 || true
            sudo -n tlp bat > /dev/null 2>&1 || tlp bat > /dev/null 2>&1 || true
            notify "Power Saver Mode" "Energy conservation active and animations disabled." "battery-caution"
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
