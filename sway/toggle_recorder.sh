#!/bin/bash
if pgrep -x wf-recorder > /dev/null; then
    killall -s SIGINT wf-recorder
    sleep 0.1
    pkill -RTMIN+9 waybar
    
    # Wait for the process to fully exit and save the video
    while pgrep -x wf-recorder > /dev/null; do sleep 0.1; done
    
    if [ -f /tmp/wf_recorder_file ]; then
        FILENAME=$(cat /tmp/wf_recorder_file)
        # Send interactive notification asynchronously
        (
            ACTION=$(notify-send -A "open=Open Location" -w "Screen Recording Saved" "Saved to $(basename "$FILENAME")" -i video-x-generic -a wf-recorder)
            if [ "$ACTION" = "open" ]; then
                # Standard D-Bus call to open file manager and highlight the specific file natively
                dbus-send --print-reply --dest=org.freedesktop.FileManager1 /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$FILENAME" string:""
            fi
        ) &
    fi
else
    mkdir -p "$HOME/Videos/Recordings"
    FILENAME="$HOME/Videos/Recordings/recording_$(date +'%Y%m%d_%H%M%S').mp4"
    echo "$FILENAME" > /tmp/wf_recorder_file
    wf-recorder -f "$FILENAME" &
    sleep 0.2
    pkill -RTMIN+9 waybar
fi
