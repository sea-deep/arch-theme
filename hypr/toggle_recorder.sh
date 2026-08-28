#!/bin/bash
# ── Section ──
# Configuration & Setup
SAVE_DIR="$HOME/Videos/Recordings"
mkdir -p "$SAVE_DIR"

# ── Section ──
# Stop Existing Recording
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT -x wf-recorder
    notify-send "Recording Stopped" "Video saved in $SAVE_DIR" -i video-x-generic -a Recorder
    pkill -RTMIN+9 -f quickshell/scripts/recorder_status.sh
    exit 0
fi

# ── Section ──
# Menu Handling
full="Full Screen\0icon\x1fvideo-display"
region="Selected Region\0icon\x1fselect-rectangular"
window="Specific Window\0icon\x1fwindow-new"
options="$full\n$region\n$window"
chosen="$(echo -e "$options" | rofi -dmenu -i -p "Record" -show-icons -theme ~/.config/rofi/powermenu.rasi -theme-str 'window {location: center; anchor: center; x-offset: 0; y-offset: 0; width: 280px;} listview {lines: 3;}')"

if [ -z "$chosen" ]; then exit 0; fi

FILENAME="$SAVE_DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"
COMMON_ARGS="-c libx264 -p preset=ultrafast -p tune=zerolatency -p crf=15 -f $FILENAME"

# ── Section ──
# Capture Logic
if [ "$chosen" = "Full Screen" ]; then
    wf-recorder $COMMON_ARGS &
elif [ "$chosen" = "Selected Region" ]; then
    GEOMETRY=$(slurp)
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    # Fix for even dimensions required by libx264
    GEOM=$(echo "$GEOMETRY" | awk -F'[, x]' '{
        w = $3; h = $4;
        if(w % 2 != 0) w++;
        if(h % 2 != 0) h++;
        print $1","$2" "w"x"h
    }')
    wf-recorder -g "$GEOM" $COMMON_ARGS &
elif [ "$chosen" = "Specific Window" ]; then
    GEOMETRY=$(hyprctl clients -j | jq -r '.[] | select(.mapped == true) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp)
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    # Fix for even dimensions required by libx264
    GEOM=$(echo "$GEOMETRY" | awk -F'[, x]' '{
        w = $3; h = $4;
        if(w % 2 != 0) w++;
        if(h % 2 != 0) h++;
        print $1","$2" "w"x"h
    }')
    wf-recorder -g "$GEOM" $COMMON_ARGS &
fi

# ── Section ──
# Notification Status
if pgrep -x wf-recorder > /dev/null; then
    notify-send "Recording Started" "Press $mainMod+Shift+R to stop" -i media-record -a Recorder
    pkill -RTMIN+9 -f quickshell/scripts/recorder_status.sh
fi
