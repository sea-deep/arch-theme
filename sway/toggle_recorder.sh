#!/bin/bash
if pgrep -x wf-recorder > /dev/null; then
    killall -s SIGINT wf-recorder
    sleep 0.1
    pkill -RTMIN+9 -f waybar/recorder.sh
    
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
    # Show selection menu before generating filename or starting
    full="Full Screen\0icon\x1fvideo-display"
    region="Selected Region\0icon\x1fselect-rectangular"
    window="Specific Window\0icon\x1fwindow-new"
    
    options="$full\n$region\n$window"
    chosen="$(echo -e "$options" | rofi -dmenu -i -p "Record" -show-icons -theme ~/.config/rofi/powermenu.rasi -theme-str 'window {location: center; anchor: center; x-offset: 0; y-offset: 0; width: 280px;} listview {lines: 3;}')"
    
    if [ -z "$chosen" ]; then
        exit 0
    fi
    
    CURSOR=$(grep 'set $cursor_theme' ~/.config/sway/config | awk '{print $3}')
    
    mkdir -p "$HOME/Videos/Recordings"
    FILENAME="$HOME/Videos/Recordings/recording_$(date +'%Y%m%d_%H%M%S').mp4"
    
    # Write the filename immediately so notifications work reliably
    echo "$FILENAME" > /tmp/wf_recorder_file
    
    case $chosen in
        "Full Screen")
            wf-recorder -a -f "$FILENAME" -p crf=15 -x yuv420p > /tmp/wf_recorder.log 2>&1 &
            ;;
        "Selected Region"|"Specific Window")
            if [ "$chosen" = "Selected Region" ]; then
                GEOMETRY=$(XCURSOR_THEME=$CURSOR XCURSOR_SIZE=32 slurp)
            else
                GEOMETRY=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | XCURSOR_THEME=$CURSOR XCURSOR_SIZE=32 slurp)
            fi
            
            if [ -n "$GEOMETRY" ]; then
                # Ensure width and height are even to prevent ffmpeg/x264 crashes
                IFS=' x,' read -r X Y W H <<< "$GEOMETRY"
                W=$(( W % 2 == 1 ? W - 1 : W ))
                H=$(( H % 2 == 1 ? H - 1 : H ))
                GEOMETRY="${X},${Y} ${W}x${H}"
                
                wf-recorder -a -g "$GEOMETRY" -f "$FILENAME" -p crf=15 -x yuv420p > /tmp/wf_recorder.log 2>&1 &
            else
                rm -f /tmp/wf_recorder_file
                exit 0
            fi
            ;;
        *)
            rm -f /tmp/wf_recorder_file
            exit 0
            ;;
    esac
    
    # Wait up to 2 seconds for it to start
    for i in {1..20}; do
        if pgrep -x wf-recorder > /dev/null; then
            pkill -RTMIN+9 -f waybar/recorder.sh
            exit 0
        fi
        sleep 0.1
    done
    
    # If we get here, it never started
    rm -f /tmp/wf_recorder_file
fi
