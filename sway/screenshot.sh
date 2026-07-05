#!/bin/bash
MODE=$1
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

if [ -z "$MODE" ] || [ "$MODE" = "menu" ]; then
    full="Full Screen\0icon\x1fvideo-display"
    region="Selected Region\0icon\x1fselect-rectangular"
    window="Specific Window\0icon\x1fwindow-new"
    
    options="$full\n$region\n$window"
    chosen="$(echo -e "$options" | rofi -dmenu -i -p "Screenshot" -show-icons -theme ~/.config/rofi/powermenu.rasi -theme-str 'window {location: center; anchor: center; x-offset: 0; y-offset: 0; width: 280px;} listview {lines: 3;}')"
    
    if [ -z "$chosen" ]; then
        exit 0
    fi
    
    if [ "$chosen" = "Full Screen" ]; then
        MODE="full"
    elif [ "$chosen" = "Selected Region" ]; then
        MODE="region"
    elif [ "$chosen" = "Specific Window" ]; then
        MODE="window"
    fi
fi

if [ "$MODE" = "full" ]; then
    grim - | wl-copy
    notify-send "Screenshot Copied" "Full screen copied to clipboard." -i image-x-generic -a Screenshot
    
elif [ "$MODE" = "region" ] || [ "$MODE" = "window" ]; then
    # Track state before swappy
    LATEST_BEFORE=$(ls -t "$SAVE_DIR" 2>/dev/null | head -n 1)
    wl-paste -t image/png > /tmp/clip_before.png 2>/dev/null
    
    # Get cursor theme from sway config for slurp
    CURSOR=$(grep 'set $cursor_theme' ~/.config/sway/config | awk '{print $3}')
    
    if [ "$MODE" = "region" ]; then
        GEOMETRY=$(XCURSOR_THEME=$CURSOR XCURSOR_SIZE=32 slurp)
    else
        GEOMETRY=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | XCURSOR_THEME=$CURSOR XCURSOR_SIZE=32 slurp)
    fi
    
    if [ -z "$GEOMETRY" ]; then exit 0; fi
    
    # Run Swappy
    grim -g "$GEOMETRY" - | swappy -f -
    
    # Wait slightly to ensure file systems and clipboard catch up
    sleep 0.2
    
    # Track state after swappy
    LATEST_AFTER=$(ls -t "$SAVE_DIR" 2>/dev/null | head -n 1)
    wl-paste -t image/png > /tmp/clip_after.png 2>/dev/null
    
    # Check if a file was saved
    if [ "$LATEST_BEFORE" != "$LATEST_AFTER" ] && [ -n "$LATEST_AFTER" ]; then
        NEW_FILE="$SAVE_DIR/$LATEST_AFTER"
        (
            ACTION=$(notify-send -A "open=Open Location" -w "Screenshot Saved" "Saved to $LATEST_AFTER" -i image-x-generic -a Swappy)
            if [ "$ACTION" = "open" ]; then
                dbus-send --print-reply --dest=org.freedesktop.FileManager1 /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$NEW_FILE" string:""
            fi
        ) &
    fi
    
    # Check if a file was copied to clipboard
    if [ -s /tmp/clip_after.png ]; then
        if [ ! -s /tmp/clip_before.png ] || ! cmp -s /tmp/clip_before.png /tmp/clip_after.png; then
            notify-send "Screenshot Copied" "Copied to clipboard." -i image-x-generic -a Swappy
        fi
    fi
fi
