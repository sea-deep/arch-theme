#!/bin/bash

# If no arguments, assume it's just being called to stop
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT -x wf-recorder
    notify-send "Recording Stopped" "Video saved in ~/Videos/Recordings" -i video-x-generic -a Recorder
    exit 0
fi

MODE=$1
QUALITY=${2:-balanced}
FORMAT=${3:-mp4}

if [ -z "$MODE" ]; then
    # We shouldn't be here without args unless stopping failed, but just in case
    exit 0
fi

SAVE_DIR="$HOME/Videos/Recordings"
mkdir -p "$SAVE_DIR"

FILENAME="$SAVE_DIR/recording_$(date +%Y%m%d_%H%M%S).$FORMAT"

# Quality Presets
if [ "$FORMAT" = "gif" ]; then
    # GIF recording via imageio or similar is hard with wf-recorder directly natively.
    # Instead we record mp4 and could convert, but wf-recorder supports GIF via lavf if compiled.
    # We will just stick to mp4/mkv. Let's fallback to mp4.
    FORMAT="mp4"
fi

if [ "$FORMAT" = "mp4" ]; then
    CODEC="libx264"
    if [ "$QUALITY" = "high" ]; then
        CRF="15"
    elif [ "$QUALITY" = "balanced" ]; then
        CRF="23"
    else
        CRF="30"
    fi
elif [ "$FORMAT" = "mkv" ]; then
    # HEVC is more efficient for MKV
    CODEC="libx265"
    if [ "$QUALITY" = "high" ]; then
        CRF="18"
    elif [ "$QUALITY" = "balanced" ]; then
        CRF="28"
    else
        CRF="35"
    fi
fi

COMMON_ARGS="-c $CODEC -p preset=fast -p tune=zerolatency -p crf=$CRF -f $FILENAME"

# ── Capture Logic ──
if [ "$MODE" = "full" ]; then
    wf-recorder $COMMON_ARGS &
elif [ "$MODE" = "region" ] || [ "$MODE" = "window" ]; then
    if [ "$MODE" = "region" ]; then
        GEOMETRY=$(slurp)
    else
        GEOMETRY=$(hyprctl clients -j | jq -r '.[] | select(.mapped == true) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp)
    fi
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    
    # Fix for even dimensions required by libx264/x265
    GEOM=$(echo "$GEOMETRY" | awk -F'[, x]' '{
        w = $3; h = $4;
        if(w % 2 != 0) w++;
        if(h % 2 != 0) h++;
        print $1","$2" "w"x"h
    }')
    wf-recorder -g "$GEOM" $COMMON_ARGS &
fi

sleep 0.5
if pgrep -x wf-recorder > /dev/null; then
    notify-send "Recording Started" "Quality: $QUALITY | Format: $FORMAT" -i media-record -a Recorder
    if command -v qs >/dev/null 2>&1; then
        qs ipc call recorder refresh >/dev/null 2>&1 || true
    fi
fi
