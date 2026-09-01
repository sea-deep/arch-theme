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
    full="Full Screen\0icon\x1fvideo-display"
    region="Selected Region\0icon\x1fselect-rectangular"
    window="Specific Window\0icon\x1fwindow-new"
    options="$full\n$region\n$window"
    chosen="$(echo -e "$options" | rofi -dmenu -i -p "Screenshot" -show-icons -theme ~/.config/rofi/powermenu.rasi -theme-str 'window {location: center; anchor: center; x-offset: 0; y-offset: 0; width: 280px;} listview {lines: 3;}')"
    if [ -z "$chosen" ]; then exit 0; fi
    if [ "$chosen" = "Full Screen" ]; then MODE="full"
    elif [ "$chosen" = "Selected Region" ]; then MODE="region"
    elif [ "$chosen" = "Specific Window" ]; then MODE="window"; fi
fi

# Check if freeze snapshot exists and is recent (< 10 seconds old)
USE_FREEZE=false
if [ -f "$FREEZE_FILE" ]; then
    FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$FREEZE_FILE" 2>/dev/null || echo 0) ))
    if [ "$FILE_AGE" -le 10 ]; then
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

        # Look up exact monitor scale for the given coordinate
        local mon_info
        mon_info=$(hyprctl monitors -j 2>/dev/null)
        local mon_s
        mon_s=$(echo "$mon_info" | jq -r --argjson x "$log_x" --argjson y "$log_y" \
            '.[] | select($x >= .x and $x < (.x + .width / .scale) and $y >= .y and $y < (.y + .height / .scale)) | .scale' 2>/dev/null | head -n 1)
        if [ -z "$mon_s" ] || [ "$mon_s" = "null" ]; then
            mon_s=$(echo "$mon_info" | jq -r '.[0].scale // 1.0' 2>/dev/null)
        fi
        if [ -z "$mon_s" ] || [ "$mon_s" = "null" ]; then mon_s=1.0; fi

        local crop_x crop_y crop_w crop_h
        crop_x=$(awk "BEGIN {printf \"%d\", ($log_x * $mon_s) + 0.5}")
        crop_y=$(awk "BEGIN {printf \"%d\", ($log_y * $mon_s) + 0.5}")
        crop_w=$(awk "BEGIN {printf \"%d\", ($log_w * $mon_s) + 0.5}")
        crop_h=$(awk "BEGIN {printf \"%d\", ($log_h * $mon_s) + 0.5}")

        magick "$FREEZE_FILE" -crop "${crop_w}x${crop_h}+${crop_x}+${crop_y}" +repage png:- | swappy -f -
    else
        # Fallback to grim capture
        sleep 0.15
        grim -g "$geometry" - | swappy -f -
    fi
}

if [ "$MODE" = "full" ]; then
    if [ "$USE_FREEZE" = true ]; then
        magick "$FREEZE_FILE" png:- | swappy -f -
    else
        sleep 0.15
        grim - | swappy -f -
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
        GEOMETRY=$(hyprctl clients -j | jq -r '.[] | select(.mapped == true and .workspace.id > 0) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp)
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
