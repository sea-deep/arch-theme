#!/bin/bash
# Power Profile & TLP Optimizer Controller
# Manages system TLP profiles, battery thresholds, and desktop shell performance modes.

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

enforce_thresholds() {
    # Actively enforce 75% start and 80% stop charge thresholds on both ThinkPad batteries
    sudo -n tlp setcharge 75 80 BAT0 > /dev/null 2>&1 || true
    sudo -n tlp setcharge 75 80 BAT1 > /dev/null 2>&1 || true
}

is_ac_online() {
    for s in /sys/class/power_supply/*; do
        local type
        type=$(cat "$s/type" 2>/dev/null)
        if [ "$type" = "Mains" ] || [ "$type" = "USB" ]; then
            if [ "$(cat "$s/online" 2>/dev/null)" = "1" ]; then
                return 0
            fi
        fi
    done
    return 1
}

get_battery_percentage() {
    local now=0
    local full=0
    for b in /sys/class/power_supply/BAT*; do
        if [ -f "$b/energy_now" ] && [ -f "$b/energy_full" ]; then
            now=$(( now + $(cat "$b/energy_now" 2>/dev/null || echo 0) ))
            full=$(( full + $(cat "$b/energy_full" 2>/dev/null || echo 0) ))
        elif [ -f "$b/charge_now" ] && [ -f "$b/charge_full" ]; then
            now=$(( now + $(cat "$b/charge_now" 2>/dev/null || echo 0) ))
            full=$(( full + $(cat "$b/charge_full" 2>/dev/null || echo 0) ))
        fi
    done
    if [ "$full" -gt 0 ]; then
        echo $(( (now * 100) / full ))
    else
        echo 100
    fi
}

apply_profile() {
    local mode="$1"
    local silent="${2:-false}"
    local reason="${3:-manual}"

    case "$mode" in
        performance)
            echo "performance" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = false } })" > /dev/null 2>&1 || true
            if is_ac_online; then
                run_tlp auto
            else
                run_tlp ac
            fi
            enforce_thresholds
            if [ "$silent" != "true" ]; then
                if [ "$reason" = "ac" ]; then
                    notify "AC Power Connected" "Performance mode active. Charge thresholds enforced (80%)." "battery-charging"
                else
                    notify "Performance Mode" "Maximum CPU frequency and fluid animations enabled." "battery-charging"
                fi
            fi
            ;;
        balanced)
            echo "balanced" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = true }, decoration = { dim_inactive = true, dim_strength = 0.15 } })" > /dev/null 2>&1 || true
            run_tlp auto
            enforce_thresholds
            if [ "$silent" != "true" ]; then
                if [ "$reason" = "battery" ]; then
                    notify "Battery Power" "Switched to Balanced mode." "battery-good"
                else
                    notify "Balanced Mode" "Dynamic CPU scaling and standard fluid animations." "battery-good"
                fi
            fi
            ;;
        powersave)
            echo "powersave" > "$STATE_FILE"
            hyprctl repl "hl.config({ animations = { enabled = false }, decoration = { dim_inactive = true, dim_strength = 0.25 } })" > /dev/null 2>&1 || true
            run_tlp bat
            if [ "$silent" != "true" ]; then
                if [ "$reason" = "low_battery" ]; then
                    local pct
                    pct=$(get_battery_percentage)
                    notify "Low Battery (${pct}%)" "Battery is at or below 30%. Switched to Power Saver mode." "battery-caution"
                else
                    notify "Power Saver Mode" "Energy conservation active and animations disabled." "battery-caution"
                fi
            fi
            ;;
        *)
            echo "Usage: $0 {set [performance|balanced|powersave]|cycle|get|restore|auto|cap}"
            exit 1
            ;;
    esac
}

auto_profile() {
    local silent="${1:-false}"
    if is_ac_online; then
        apply_profile "performance" "$silent" "ac"
    else
        local pct
        pct=$(get_battery_percentage)
        if [ "$pct" -le 30 ]; then
            apply_profile "powersave" "$silent" "low_battery"
        else
            apply_profile "balanced" "$silent" "battery"
        fi
    fi
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
        apply_profile "$2" "${3:-false}" "${4:-manual}"
        ;;
    auto)
        auto_profile "${2:-false}"
        ;;
    cap)
        enforce_thresholds
        notify "Battery Thresholds" "Charge thresholds set to 75% start / 80% stop for BAT0 and BAT1." "battery-good"
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
        auto_profile "true"
        ;;
    *)
        echo "Usage: $0 {set [performance|balanced|powersave]|cycle|get|restore|auto|cap}"
        exit 1
        ;;
esac
