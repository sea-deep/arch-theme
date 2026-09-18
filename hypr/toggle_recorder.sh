#!/bin/bash

# If no arguments, assume it's being called to stop an active recording
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT -x wf-recorder
    notify-send "Recording Stopped" "Video saved in ~/Videos/Recordings" -i video-x-generic -a Recorder
    exit 0
fi

MODE=$1
QUALITY=${2:-balanced}
FORMAT=${3:-mp4}

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

# ── Capture Logic ─────────────────────────────────────────────────────────────
case "$MODE" in
    full)
        wf-recorder "${WFR_ARGS[@]}" &
        ;;
    region)
        GEOMETRY=$(slurp) || exit 0
        GEOM=$(ensure_even_geom "$GEOMETRY")
        wf-recorder -g "$GEOM" "${WFR_ARGS[@]}" &
        ;;
    window)
        # Select from windows on current active workspace or floating windows.
        # -r restricts slurp to selecting one of the exact window bounding boxes.
        ACTIVE_WS=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')
        GEOMETRY=$(hyprctl clients -j \
            | jq -r --argjson ws "$ACTIVE_WS" '.[] | select(.mapped == true and (.workspace.id == $ws or .floating == true)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
            | slurp -r) || exit 0
        GEOM=$(ensure_even_geom "$GEOMETRY")
        wf-recorder -g "$GEOM" "${WFR_ARGS[@]}" &
        ;;
esac

sleep 0.5
if pgrep -x wf-recorder > /dev/null; then
    notify-send "Recording Started" "Quality: $QUALITY | Format: $FORMAT | ${FPS}fps" -i media-record -a Recorder
    command -v qs >/dev/null 2>&1 && qs ipc call recorder refresh >/dev/null 2>&1 || true
fi
