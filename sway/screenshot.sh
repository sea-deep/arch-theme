#!/bin/bash
MODE=$1
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

if [ "$MODE" = "full" ]; then
    grim - | wl-copy
    notify-send "Screenshot Copied" "Full screen copied to clipboard." -i image-x-generic -a Screenshot
    
elif [ "$MODE" = "region" ]; then
    # Track state before swappy
    LATEST_BEFORE=$(ls -t "$SAVE_DIR" 2>/dev/null | head -n 1)
    wl-paste -t image/png > /tmp/clip_before.png 2>/dev/null
    
    # Get cursor theme from sway config for slurp
    CURSOR=$(grep 'set $cursor_theme' ~/.config/sway/config | awk '{print $3}')
    
    # Run Swappy
    grim -g "$(XCURSOR_THEME=$CURSOR XCURSOR_SIZE=32 slurp)" - | swappy -f -
    
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
