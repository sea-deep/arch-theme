#!/bin/bash

# Cleanup helper for any combined audio sink and loopback modules
clean_audio_state() {
    local sf="/tmp/wf-recorder-audio-$UID.state"
    if [ -f "$sf" ]; then
        read -r s l1 l2 < "$sf"
        [ -n "$l1" ] && pactl unload-module "$l1" 2>/dev/null || true
        [ -n "$l2" ] && pactl unload-module "$l2" 2>/dev/null || true
        [ -n "$s" ] && pactl unload-module "$s" 2>/dev/null || true
        rm -f "$sf"
    fi
    local leftover_mods
    leftover_mods=$(pactl list modules short 2>/dev/null | awk '/sink_name=WfCombined|sink=WfCombined/ {print $1}')
    for m in $leftover_mods; do
        pactl unload-module "$m" 2>/dev/null || true
    done
}

# If no arguments, assume it's being called to stop an active recording
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT -x wf-recorder
    clean_audio_state
    notify-send "Recording Stopped" "Video saved in ~/Videos/Recordings" -i video-x-generic -a Recorder
    exit 0
fi

MODE=$1
QUALITY=${2:-balanced}
FORMAT=${3:-mp4}
AUDIO=${4:-none}

if [ -z "$MODE" ]; then
    exit 0
fi

SAVE_DIR="$HOME/Videos/Recordings"
mkdir -p "$SAVE_DIR"

FILENAME="$SAVE_DIR/recording_$(date +%Y%m%d_%H%M%S).$FORMAT"
FPS=60

# ── Codec & Quality Presets ──────────────────────────────────────────────────
# Use libx264 for universal compatibility and high-performance real-time 60fps encoding.
# scale=out_color_matrix=bt709:out_range=tv converts full-range sRGB [0..255] to standard
# BT.709 TV range [16..235] and tags the stream. This prevents washed-out/milky colors
# and ensures deep blacks and accurate saturation across all players and browsers.
CODEC="libx264"
case "$QUALITY" in
    high)     CRF=18 ;;
    balanced) CRF=23 ;;
    *)        CRF=28 ;;
esac

# ── Geometry Correction ─────────────────────────────────────────────────────
# wf-recorder expects logical pixel coordinates and handles monitor scaling
# internally via Wayland protocols. We only ensure even dimensions for libx264.
ensure_even_geom() {
    local geom="$1"
    echo "$geom" | awk -F'[, x]' '{
        x = $1; y = $2; w = $3; h = $4;
        if (w % 2 != 0) w++
        if (h % 2 != 0) h++
        print x","y" "w"x"h
    }'
}

# ── Audio Source Configuration ──────────────────────────────────────────────
AUDIO_LABEL="Off"
AUDIO_DEV=""
NEED_AUDIO_CLEANUP=false

case "$AUDIO" in
    device)
        DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
        if [ -n "$DEFAULT_SINK" ]; then
            AUDIO_DEV="${DEFAULT_SINK}.monitor"
            AUDIO_LABEL="Device"
        fi
        ;;
    mic)
        DEFAULT_SOURCE=$(pactl get-default-source 2>/dev/null)
        if [ -n "$DEFAULT_SOURCE" ]; then
            AUDIO_DEV="$DEFAULT_SOURCE"
            AUDIO_LABEL="Mic"
        fi
        ;;
    both)
        clean_audio_state
        SINK_ID=$(pactl load-module module-null-sink sink_name=WfCombined sink_properties=device.description=WfCombined 2>/dev/null)
        DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
        L1=$(pactl load-module module-loopback sink=WfCombined source="${DEFAULT_SINK}.monitor" 2>/dev/null)
        DEFAULT_SOURCE=$(pactl get-default-source 2>/dev/null)
        L2=$(pactl load-module module-loopback sink=WfCombined source="$DEFAULT_SOURCE" 2>/dev/null)
        
        STATE_FILE="/tmp/wf-recorder-audio-$UID.state"
        echo "$SINK_ID $L1 $L2" > "$STATE_FILE"
        AUDIO_DEV="WfCombined.monitor"
        AUDIO_LABEL="Device + Mic"
        NEED_AUDIO_CLEANUP=true
        ;;
    *)
        AUDIO_DEV=""
        AUDIO_LABEL="Off"
        ;;
esac

# ── wf-recorder base args (array for safe quoting) ───────────────────────────
WFR_ARGS=(
    -r "$FPS"
    -c "$CODEC"
    -F "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p"
    -p preset=fast
    -p crf="$CRF"
    -p color_range=1
    -p colorspace=1
    -p color_primaries=1
    -p color_trc=1
    -f "$FILENAME"
)

if [ -n "$AUDIO_DEV" ]; then
    WFR_ARGS+=(--audio="$AUDIO_DEV")
fi

# ── Capture Logic ─────────────────────────────────────────────────────────────
RECORD_PID=""
case "$MODE" in
    full)
        wf-recorder "${WFR_ARGS[@]}" &
        RECORD_PID=$!
        ;;
    region)
        GEOMETRY=$(slurp) || { [ "$NEED_AUDIO_CLEANUP" = true ] && clean_audio_state; exit 0; }
        GEOM=$(ensure_even_geom "$GEOMETRY")
        wf-recorder -g "$GEOM" "${WFR_ARGS[@]}" &
        RECORD_PID=$!
        ;;
    window)
        # Select from windows on current active workspace or floating windows.
        # -r restricts slurp to selecting one of the exact window bounding boxes.
        ACTIVE_WS=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')
        GEOMETRY=$(hyprctl clients -j \
            | jq -r --argjson ws "$ACTIVE_WS" '.[] | select(.mapped == true and (.workspace.id == $ws or .floating == true)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
            | slurp -r) || { [ "$NEED_AUDIO_CLEANUP" = true ] && clean_audio_state; exit 0; }
        GEOM=$(ensure_even_geom "$GEOMETRY")
        wf-recorder -g "$GEOM" "${WFR_ARGS[@]}" &
        RECORD_PID=$!
        ;;
esac

# If combined audio was used, spawn a watcher to clean up loopback modules as soon as wf-recorder finishes
if [ "$NEED_AUDIO_CLEANUP" = true ] && [ -n "$RECORD_PID" ]; then
    (
        while kill -0 "$RECORD_PID" 2>/dev/null; do
            sleep 0.5
        done
        clean_audio_state
    ) &
fi

sleep 0.5
if pgrep -x wf-recorder > /dev/null; then
    notify-send "Recording Started" "Quality: $QUALITY | Format: $FORMAT | Audio: $AUDIO_LABEL | ${FPS}fps" -i media-record -a Recorder
    command -v qs >/dev/null 2>&1 && qs ipc call recorder refresh >/dev/null 2>&1 || true
fi
