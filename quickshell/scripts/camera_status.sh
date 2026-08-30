#!/usr/bin/env bash
check_camera() {
    if fuser /dev/video* 2>/dev/null | grep -q '[0-9]'; then
        echo '{"active":true}'
        return
    fi
    if pw-dump 2>/dev/null | jq -e '.[] | select(.info.props["media.class"] == "Video/Source" and .info.state == "running")' >/dev/null 2>&1; then
        echo '{"active":true}'
        return
    fi
    echo '{"active":false}'
}

check_camera

while true; do
    sleep 1.5
    check_camera
done
