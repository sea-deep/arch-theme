#!/bin/bash
# ── Section ──
# Configuration & Setup
MODE=$1
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

FREEZE_FILE="/tmp/qs_screenshot_freeze.ppm"

# ── Section ──
# Menu Handling
if [ -z "$MODE" ] || [ "$MODE" = "menu" ]; then
    if command -v qs >/dev/null 2>&1 && pgrep -x qs >/dev/null 2>&1; then
        qs ipc call screenshot toggle && exit 0
    fi
    MODE="region"
fi

# Check if freeze snapshot exists and is recent (< 60 seconds old)
USE_FREEZE=false
if [ -f "$FREEZE_FILE" ]; then
    FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$FREEZE_FILE" 2>/dev/null || echo 0) ))
    if [ "$FILE_AGE" -le 60 ]; then
        USE_FREEZE=true
    fi
fi

LATEST_BEFORE=$(ls -t "$SAVE_DIR" 2>/dev/null | head -n 1)
wl-paste -t image/png > /tmp/clip_before.png 2>/dev/null

GEOM=$2

# Helper function to crop from frozen image or fall back to grim
crop_and_pipe() {
    local geometry="$1"
    if [ "$USE_FREEZE" = true ] && [[ "$geometry" =~ ([0-9]+),([0-9]+)[[:space:]]+([0-9]+)x([0-9]+) ]]; then
        local log_x="${BASH_REMATCH[1]}"
        local log_y="${BASH_REMATCH[2]}"
        local log_w="${BASH_REMATCH[3]}"
        local log_h="${BASH_REMATCH[4]}"

        # Look up monitor scale and convert to physical coordinates in one fast jq call
        local mon_info
        mon_info=$(hyprctl monitors -j 2>/dev/null)
        local crop_x crop_y crop_w crop_h
        read -r crop_x crop_y crop_w crop_h <<< $(echo "$mon_info" | jq -r --argjson x "$log_x" --argjson y "$log_y" --argjson w "$log_w" --argjson h "$log_h" '
            ( .[] | select($x >= .x and $x < (.x + .width / .scale) and $y >= .y and $y < (.y + .height / .scale)) | .scale ) // .[0].scale // 1.0 as $s |
            "\((($x * $s) + 0.5 | floor)) \((($y * $s) + 0.5 | floor)) \((($w * $s) + 0.5 | floor)) \((($h * $s) + 0.5 | floor))"
        ' 2>/dev/null | head -n 1)

        [ -z "$crop_w" ] && crop_w="$log_w"
        [ -z "$crop_h" ] && crop_h="$log_h"
        [ -z "$crop_x" ] && crop_x="$log_x"
        [ -z "$crop_y" ] && crop_y="$log_y"

        # Pipe directly as uncompressed PPM to swappy.
        # This eliminates the 800-1000ms PNG compression bottleneck of ImageMagick.
        magick "$FREEZE_FILE" -crop "${crop_w}x${crop_h}+${crop_x}+${crop_y}" +repage ppm:- | swappy -f -
    else
        # Fast direct grim capture in ppm format
        grim -g "$geometry" -t ppm - | swappy -f -
    fi
}

if [ "$MODE" = "full" ]; then
    if [ "$USE_FREEZE" = true ]; then
        swappy -f "$FREEZE_FILE"
    else
        grim -t ppm - | swappy -f -
    fi
elif [ "$MODE" = "region" ]; then
    if [ -n "$GEOM" ]; then
        GEOMETRY="$GEOM"
    else
        GEOMETRY=$(slurp)
    fi
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    crop_and_pipe "$GEOMETRY"
elif [ "$MODE" = "window" ]; then
    if [ -n "$GEOM" ]; then
        GEOMETRY="$GEOM"
    else
        ACTIVE_WS=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')
        GEOMETRY=$(hyprctl clients -j | jq -r --argjson ws "$ACTIVE_WS" '.[] | select(.mapped == true and (.workspace.id == $ws or .floating == true)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -r)
    fi
    if [ -z "$GEOMETRY" ]; then
        GEOMETRY=$(slurp)
    fi
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    crop_and_pipe "$GEOMETRY"
fi

sleep 0.2
LATEST_AFTER=$(ls -t "$SAVE_DIR" 2>/dev/null | head -n 1)
wl-paste -t image/png > /tmp/clip_after.png 2>/dev/null

if [ "$LATEST_BEFORE" != "$LATEST_AFTER" ] && [ -n "$LATEST_AFTER" ]; then
    NEW_FILE="$SAVE_DIR/$LATEST_AFTER"
    ( ACTION=$(notify-send -A "open=Open Location" -w "Screenshot Saved" "Saved to $LATEST_AFTER" -i image-x-generic -a Swappy)
      if [ "$ACTION" = "open" ]; then
          dbus-send --print-reply --dest=org.freedesktop.FileManager1 /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$NEW_FILE" string:""
      fi ) &
fi

if [ -s /tmp/clip_after.png ]; then
    if [ ! -s /tmp/clip_before.png ] || ! cmp -s /tmp/clip_before.png /tmp/clip_after.png; then
        notify-send "Screenshot Copied" "Copied to clipboard." -i image-x-generic -a Swappy
    fi
fi
