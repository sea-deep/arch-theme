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
# pix_fmt=yuv420p is required for broad player compatibility (VLC, browsers, etc.)
# tune=zerolatency intentionally omitted — it's for live streaming, not file recording
if [ "$FORMAT" = "mp4" ]; then
    CODEC="libx264"
    case "$QUALITY" in
        high)     CRF=15 ;;
        balanced) CRF=23 ;;
        *)        CRF=30 ;;
    esac
elif [ "$FORMAT" = "mkv" ]; then
    CODEC="libx265"
    case "$QUALITY" in
        high)     CRF=18 ;;
        balanced) CRF=28 ;;
        *)        CRF=35 ;;
    esac
fi

# ── Scale: logical px → physical px ─────────────────────────────────────────
# hyprctl reports window coords in logical pixels; wf-recorder needs physical pixels.
# Without this, window mode records only the inner portion of the window at fractional scales.
SCALE=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].scale // "1"')

scale_geom() {
    local geom="$1"
    echo "$geom" | awk -v s="$SCALE" -F'[, x]' '{
        x = int($1 * s + 0.5)
        y = int($2 * s + 0.5)
        w = int($3 * s + 0.5)
        h = int($4 * s + 0.5)
        if (w % 2 != 0) w++
        if (h % 2 != 0) h++
        print x","y" "w"x"h
    }'
}

# ── wf-recorder base args (array for safe quoting) ───────────────────────────
WFR_ARGS=(
    -r "$FPS"
    -c "$CODEC"
    -p preset=fast
    -p crf="$CRF"
    -p pix_fmt=yuv420p
    -f "$FILENAME"
)

# ── Capture Logic ─────────────────────────────────────────────────────────────
case "$MODE" in
    full)
        wf-recorder "${WFR_ARGS[@]}" &
        ;;
    region)
        GEOMETRY=$(slurp) || exit 0
        GEOM=$(scale_geom "$GEOMETRY")
        wf-recorder -g "$GEOM" "${WFR_ARGS[@]}" &
        ;;
    window)
        # Pipe all mapped window geometries into slurp so the user can click to pick one
        GEOMETRY=$(hyprctl clients -j \
            | jq -r '.[] | select(.mapped == true) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
            | slurp) || exit 0
        GEOM=$(scale_geom "$GEOMETRY")
        wf-recorder -g "$GEOM" "${WFR_ARGS[@]}" &
        ;;
esac

sleep 0.5
if pgrep -x wf-recorder > /dev/null; then
    notify-send "Recording Started" "Quality: $QUALITY | Format: $FORMAT | ${FPS}fps" -i media-record -a Recorder
    command -v qs >/dev/null 2>&1 && qs ipc call recorder refresh >/dev/null 2>&1 || true
fi
