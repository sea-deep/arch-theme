#!/bin/bash
# ── Section ──
# Configuration & Setup
MODE=$1
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

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

# ── Section ──
# Capture Logic
# Wait for any overlay layer-surfaces to unmap and release focus
sleep 0.15

LATEST_BEFORE=$(ls -t "$SAVE_DIR" 2>/dev/null | head -n 1)
wl-paste -t image/png > /tmp/clip_before.png 2>/dev/null

GEOM=$2

if [ "$MODE" = "full" ]; then
    grim - | swappy -f -
elif [ "$MODE" = "region" ]; then
    if [ -n "$GEOM" ]; then
        GEOMETRY="$GEOM"
    else
        GEOMETRY=$(slurp)
    fi
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    grim -g "$GEOMETRY" - | swappy -f -
elif [ "$MODE" = "window" ]; then
    if [ -n "$GEOM" ]; then
        GEOMETRY="$GEOM"
    else
        GEOMETRY=$(hyprctl clients -j | jq -r '.[] | select(.mapped == true and .workspace.id > 0) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp)
    fi
    if [ -z "$GEOMETRY" ]; then
        # Fallback to standard slurp if no window was picked
        GEOMETRY=$(slurp)
    fi
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    grim -g "$GEOMETRY" - | swappy -f -
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
