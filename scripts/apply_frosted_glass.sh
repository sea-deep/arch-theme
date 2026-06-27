#!/bin/bash
set -e

echo "==========================================="
echo "   Waybar Frosted Glass Frame Generator    "
echo "==========================================="
echo ""

# 1. Get Input
if [ -z "$1" ]; then
    read -p "Enter path to INPUT image: " INPUT
else
    INPUT="$1"
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' does not exist."
    exit 1
fi

# 2. Get Output
if [ -z "$2" ]; then
    read -p "Enter path for OUTPUT image: " OUTPUT
else
    OUTPUT="$2"
fi

# 3. Check input image dimensions
DIMENSIONS=$(magick identify -format "%wx%h" "$INPUT" 2>/dev/null || echo "error")
if [ "$DIMENSIONS" == "error" ]; then
    echo "Error: Could not read image dimensions. Is it a valid image file?"
    exit 1
fi

# 4. Auto-detect display resolution from Sway (or fall back to manual input)
if command -v swaymsg &> /dev/null && swaymsg -t get_outputs &> /dev/null; then
    DETECTED=$(swaymsg -t get_outputs | jq -r '.[0] | "\(.current_mode.width)x\(.current_mode.height)"')
    TARGET_W=$(echo "$DETECTED" | cut -dx -f1)
    TARGET_H=$(echo "$DETECTED" | cut -dx -f2)
    echo "Auto-detected display resolution: ${TARGET_W}x${TARGET_H}"
else
    echo "Could not auto-detect display resolution (Sway not running?)."
    read -p "Enter target resolution (e.g. 1920x1080): " MANUAL_RES
    TARGET_W=$(echo "$MANUAL_RES" | cut -dx -f1)
    TARGET_H=$(echo "$MANUAL_RES" | cut -dx -f2)
fi

WORKING_FILE="$INPUT"
TEMP_RESIZED="temp_resized_$$.png"

if [ "$DIMENSIONS" != "${TARGET_W}x${TARGET_H}" ]; then
    echo "Warning: Image is $DIMENSIONS. Target is ${TARGET_W}x${TARGET_H}."
    echo "How would you like to resize it?"
    echo "  1) Crop to Fill (Preserves aspect ratio, cuts off edges to fit)"
    echo "  2) Stretch to Fit (Distorts aspect ratio to force it)"
    echo "  3) Abort"
    read -p "Select option [1-3]: " RESIZE_OPT

    case $RESIZE_OPT in
        1)
            echo "Resizing and cropping to fill..."
            magick "$INPUT" -resize ${TARGET_W}x${TARGET_H}^ -gravity center -extent ${TARGET_W}x${TARGET_H} "$TEMP_RESIZED"
            WORKING_FILE="$TEMP_RESIZED"
            ;;
        2)
            echo "Stretching to fit..."
            magick "$INPUT" -resize ${TARGET_W}x${TARGET_H}\! "$TEMP_RESIZED"
            WORKING_FILE="$TEMP_RESIZED"
            ;;
        *)
            echo "Aborting."
            exit 0
            ;;
    esac
else
    echo "Image already matches display resolution! Proceeding..."
fi

echo ""
echo "Generating mask components..."

# 1. Top Mask (80px solid + 30px fade + rest black)
magick -size ${TARGET_W}x80 xc:white mask_top_solid.png
magick -size ${TARGET_W}x30 gradient:white-black mask_top_fade.png
magick -size ${TARGET_W}x2050 xc:black mask_top_rest.png
magick mask_top_solid.png mask_top_fade.png mask_top_rest.png -append mask_top_full.png

# 2. Bottom Mask (rest black + 30px fade)
magick -size ${TARGET_W}x2130 xc:black mask_bottom_rest.png
magick -size ${TARGET_W}x30 gradient:black-white mask_bottom_fade.png
magick mask_bottom_rest.png mask_bottom_fade.png -append mask_bottom_full.png

# 3. Left Mask (30px fade on left, rest black)
magick -size 30x${TARGET_H} -define gradient:direction=east gradient:white-black mask_left_fade.png
magick mask_left_fade.png -background black -extent ${TARGET_W}x${TARGET_H} mask_left_full.png

# 4. Right Mask (30px fade on right, rest black)
magick -size 30x${TARGET_H} -define gradient:direction=west gradient:white-black mask_right_fade.png
magick mask_right_fade.png -gravity east -background black -extent ${TARGET_W}x${TARGET_H} mask_right_full.png

echo "Compositing masks together..."
magick mask_top_full.png mask_bottom_full.png -compose Screen -composite \
       mask_left_full.png -compose Screen -composite \
       mask_right_full.png -compose Screen -composite \
       final_mask.png

echo "Processing blurred background..."
# Pure 25px blur with no color tint (v10 specs)
magick "$WORKING_FILE" -blur 0x25 fully_blurred.png

echo "Applying final compositing..."
magick "$WORKING_FILE" fully_blurred.png final_mask.png -composite "$OUTPUT"

# Generate corresponding Swaylock background (1080p + Tokyo Night 60% tint)
OUTPUT_LOCK="${OUTPUT%.*}_lock.${OUTPUT##*.}"
echo "Generating matching Swaylock background..."
magick "$WORKING_FILE" -blur 0x40 -fill "#1a1b26" -colorize 60% -resize ${TARGET_W}x${TARGET_H} "$OUTPUT_LOCK"

echo "Cleaning up..."
rm mask_top_solid.png mask_top_fade.png mask_top_rest.png mask_top_full.png
rm mask_bottom_rest.png mask_bottom_fade.png mask_bottom_full.png
rm mask_left_fade.png mask_left_full.png
rm mask_right_fade.png mask_right_full.png
rm final_mask.png fully_blurred.png

if [ -f "$TEMP_RESIZED" ]; then
    rm "$TEMP_RESIZED"
fi

echo "==========================================="
echo "Done! Generated files:"
echo "1) Desktop: $OUTPUT"
echo "2) Lockscreen: $OUTPUT_LOCK"
echo "==========================================="
