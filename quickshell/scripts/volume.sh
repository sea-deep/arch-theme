#!/bin/bash
# ~/.config/quickshell/scripts/volume.sh
export LC_ALL=C

get_volume() {
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    # Output is like: Volume: 0.58 [MUTED]
    
    if [ -z "$vol" ]; then
        echo '{"volume": 0, "muted": true, "error": true}'
        return
    fi
    
    percent=$(echo "$vol" | awk '{print int($2 * 100)}')
    muted=false
    if echo "$vol" | grep -q "MUTED"; then
        muted=true
    fi
    
    jq -c -n --unbuffered \
      --argjson volume "$percent" \
      --argjson muted "$muted" \
      --argjson error false \
      '{"volume": $volume, "muted": $muted, "error": $error}'
}

# Initial state
get_volume

# Monitor pactl for changes
pactl subscribe 2>/dev/null | grep --line-buffered "Event 'change' on sink" | while read -r line; do
    get_volume
done
