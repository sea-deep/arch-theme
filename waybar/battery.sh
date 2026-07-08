#!/bin/bash

# Ensure output is unbuffered
export PYTHONUNBUFFERED=1

read_file() {
    [ -f "$1" ] && cat "$1" || echo ""
}

update_battery() {
    bat0_cap=$(read_file /sys/class/power_supply/BAT0/capacity)
    bat1_cap=$(read_file /sys/class/power_supply/BAT1/capacity)
    bat0_stat=$(read_file /sys/class/power_supply/BAT0/status)
    bat1_stat=$(read_file /sys/class/power_supply/BAT1/status)
    
    bat0_energy_now=$(read_file /sys/class/power_supply/BAT0/energy_now)
    [ -z "$bat0_energy_now" ] && bat0_energy_now=$(read_file /sys/class/power_supply/BAT0/charge_now)
    bat0_energy_full=$(read_file /sys/class/power_supply/BAT0/energy_full)
    [ -z "$bat0_energy_full" ] && bat0_energy_full=$(read_file /sys/class/power_supply/BAT0/charge_full)
    
    bat1_energy_now=$(read_file /sys/class/power_supply/BAT1/energy_now)
    [ -z "$bat1_energy_now" ] && bat1_energy_now=$(read_file /sys/class/power_supply/BAT1/charge_now)
    bat1_energy_full=$(read_file /sys/class/power_supply/BAT1/energy_full)
    [ -z "$bat1_energy_full" ] && bat1_energy_full=$(read_file /sys/class/power_supply/BAT1/charge_full)
    
    total_cap=0
    if [ -n "$bat0_energy_now" ] && [ -n "$bat1_energy_now" ] && [ -n "$bat0_energy_full" ] && [ -n "$bat1_energy_full" ]; then
        total_now=$((bat0_energy_now + bat1_energy_now))
        total_full=$((bat0_energy_full + bat1_energy_full))
        if [ "$total_full" -gt 0 ]; then
            total_cap=$((total_now * 100 / total_full))
        fi
    elif [ -n "$bat0_cap" ] && [ -n "$bat1_cap" ]; then
        total_cap=$(((bat0_cap + bat1_cap) / 2))
    elif [ -n "$bat0_cap" ]; then
        total_cap=$bat0_cap
    fi
    
    status="Discharging"
    if [ "$bat0_stat" = "Charging" ] || [ "$bat1_stat" = "Charging" ]; then
        status="Charging"
    elif [ "$bat0_stat" = "Full" ] || [ "$bat1_stat" = "Full" ]; then
        status="Full"
    fi
    
    icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
    charging_icon="󰂄"
    
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        icon="$charging_icon"
    else
        idx=$((total_cap / 10))
        [ "$idx" -gt 10 ] && idx=10
        icon="${icons[$idx]}"
    fi
    
    tooltip="Internal (BAT0): ${bat0_cap}% (${bat0_stat})\nExternal (BAT1): ${bat1_cap}% (${bat1_stat})"
    if [ -z "$bat1_cap" ]; then
        tooltip="Internal (BAT0): ${bat0_cap}% (${bat0_stat})"
    fi
    
    tlp_profile=$(tlp-stat -s 2>/dev/null | grep "TLP profile" | cut -d'=' -f2 | xargs)
    if [ -n "$tlp_profile" ]; then
        tooltip="${tooltip}\nPower Profile: ${tlp_profile}"
    fi
    
    class_name=$(echo "$status" | tr '[:upper:]' '[:lower:]')
    
    jq -c -n --unbuffered \
      --arg text "${total_cap}%" \
      --arg alt "$icon" \
      --arg tooltip "$(echo -e "$tooltip")" \
      --arg class "$class_name" \
      --argjson percentage "$total_cap" \
      '{"text": $text, "alt": $alt, "tooltip": $tooltip, "class": $class, "percentage": $percentage}'
}

# Run once initially to populate Waybar on startup
update_battery

# Monitor upower for changes using a debouncer to prevent excessive updates
# stdbuf ensures lines aren't buffered in the pipe
stdbuf -oL upower --monitor | while true; do
    # Block and wait for an event
    read -r line || break
    
    update_battery
    
    # Consume any extra simultaneous events within a 100ms window
    # so we don't run tlp-stat 5 times for a single plug/unplug action
    while read -t 0.1 -r extra; do
        :
    done
done
