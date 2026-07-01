#!/bin/bash
if pgrep -x wf-recorder > /dev/null; then
    killall -s SIGINT wf-recorder
    sleep 0.1
    pkill -RTMIN+9 waybar
else
    mkdir -p "$HOME/Videos/Recordings"
    wf-recorder -f "$HOME/Videos/Recordings/recording_$(date +'%Y%m%d_%H%M%S').mp4" &
    sleep 0.2
    pkill -RTMIN+9 waybar
fi
