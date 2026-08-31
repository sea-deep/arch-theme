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

run_tlp() {
    local cmd="$1"
    # Try non-interactive sudo first (if NOPASSWD in sudoers)
    if sudo -n tlp "$cmd" > /dev/null 2>&1; then
        return 0
    fi
    # Fallback to pkexec (handles Polkit rules or graphical auth dialog)
    if command -v pkexec > /dev/null 2>&1; then
        pkexec tlp "$cmd" > /dev/null 2>&1 || true
    fi
}

apply_profile() {
    local mode="$1"
    local silent="${2:-false}"
    case "$mode" in
        performance)
            echo "performance" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = false } })" > /dev/null 2>&1 || true
            run_tlp ac
            if [ "$silent" != "true" ]; then
                notify "Performance Mode" "Maximum CPU frequency and fluid animations enabled." "battery-charging"
            fi
            ;;
        balanced)
            echo "balanced" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = true, dim_strength = 0.15 } })" > /dev/null 2>&1 || true
            run_tlp auto
            if [ "$silent" != "true" ]; then
                notify "Balanced Mode" "Dynamic CPU scaling and standard fluid animations." "battery-good"
            fi
            ;;
        powersave)
            echo "powersave" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = false }, decoration = { dim_inactive = true, dim_strength = 0.25 } })" > /dev/null 2>&1 || true
            run_tlp bat
            if [ "$silent" != "true" ]; then
                notify "Power Saver Mode" "Energy conservation active and animations disabled." "battery-caution"
            fi
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
        apply_profile "$current" "true"
        ;;
    *)
        echo "Usage: $0 {set [performance|balanced|powersave]|cycle|get|restore}"
        exit 1
        ;;
esac
