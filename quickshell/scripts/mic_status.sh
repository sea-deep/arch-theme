#!/usr/bin/env bash
check_mic() {
    local count
    count=$(pactl list source-outputs 2>/dev/null | grep -c "Corked: no")
    if [ "$count" -gt 0 ]; then
        echo '{"active":true}'
    else
        echo '{"active":false}'
    fi
}

check_mic

pactl subscribe 2>/dev/null | grep --line-buffered "source-output" | while read -r _; do
    check_mic
done
