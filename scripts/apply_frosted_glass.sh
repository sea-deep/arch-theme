#!/bin/bash
set -eo pipefail

echo "==========================================="
echo "   Waybar Frosted Glass Frame Generator    "
echo "==========================================="
echo ""

# --- Dependency Check ---
for cmd in magick jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: '$cmd' is required but not installed."
        [ "$cmd" == "magick" ] && echo "  Install: sudo pacman -S imagemagick"
        [ "$cmd" == "jq" ] && echo "  Install: sudo pacman -S jq"
        exit 1
    fi
done

# --- Temp Directory (all intermediate files go here, auto-cleaned on exit) ---
TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/frosted_glass_XXXXXX")
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# --- 1. Get Input ---
if [ -z "$1" ]; then
    read -rp "Enter path to INPUT image: " INPUT
else
    INPUT="$1"
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' does not exist."
    exit 1
fi

# --- 2. Get Output ---
if [ -z "$2" ]; then
    read -rp "Enter path for OUTPUT image: " OUTPUT
else
    OUTPUT="$2"
fi

# Validate output directory exists
OUTPUT_DIR=$(dirname "$OUTPUT")
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Output directory '$OUTPUT_DIR' does not exist."
    exit 1
fi

# --- 3. Check Input Image Dimensions ---
DIMENSIONS=$(magick identify -format "%wx%h" "$INPUT" 2>/dev/null) || {
    echo "Error: Could not read image dimensions. Is '$INPUT' a valid image file?"
    exit 1
}

# --- 4. Auto-detect Display Resolution ---
if command -v swaymsg &> /dev/null && swaymsg -t get_outputs &> /dev/null 2>&1; then
    DETECTED=$(swaymsg -t get_outputs | jq -r '.[0] | "\(.current_mode.width)x\(.current_mode.height)"')
    TARGET_W=$(echo "$DETECTED" | cut -dx -f1)
    TARGET_H=$(echo "$DETECTED" | cut -dx -f2)
    echo "Auto-detected display resolution: ${TARGET_W}x${TARGET_H}"
else
    echo "Could not auto-detect display resolution (Sway not running?)."
    read -rp "Enter target resolution (e.g. 1920x1080): " MANUAL_RES

    # Validate format
    if ! [[ "$MANUAL_RES" =~ ^[0-9]+x[0-9]+$ ]]; then
        echo "Error: Invalid resolution format. Expected WIDTHxHEIGHT (e.g. 1920x1080)."
        exit 1
    fi

    TARGET_W=$(echo "$MANUAL_RES" | cut -dx -f1)
    TARGET_H=$(echo "$MANUAL_RES" | cut -dx -f2)
fi

# Sanity check resolution values
if [ "$TARGET_W" -lt 100 ] || [ "$TARGET_H" -lt 100 ] 2>/dev/null; then
    echo "Error: Resolution ${TARGET_W}x${TARGET_H} is too small."
    exit 1
fi

# --- 5. Resize Input if Needed ---
WORKING_FILE="$INPUT"

if [ "$DIMENSIONS" != "${TARGET_W}x${TARGET_H}" ]; then
    echo "Warning: Image is $DIMENSIONS. Target is ${TARGET_W}x${TARGET_H}."
    echo "How would you like to resize it?"
    echo "  1) Crop to Fill (Preserves aspect ratio, cuts off edges to fit)"
    echo "  2) Stretch to Fit (Distorts aspect ratio to force it)"
    echo "  3) Abort"
    read -rp "Select option [1-3]: " RESIZE_OPT

    RESIZED="$TMPDIR/resized.png"
    case $RESIZE_OPT in
        1)
            echo "Resizing and cropping to fill..."
            magick "$INPUT" -resize "${TARGET_W}x${TARGET_H}^" -gravity center -extent "${TARGET_W}x${TARGET_H}" "$RESIZED"
            WORKING_FILE="$RESIZED"
            ;;
        2)
            echo "Stretching to fit..."
            magick "$INPUT" -resize "${TARGET_W}x${TARGET_H}!" "$RESIZED"
            WORKING_FILE="$RESIZED"
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

# --- 6. Generate Edge Masks (dynamically computed from target resolution) ---
# Waybar strip: 80px solid blur at the top + 30px gradient fade
# All other edges: 30px gradient fade
# The "rest" height/width fills the remainder with solid black (no blur)

TOP_SOLID=80
FADE=30
TOP_REST=$(( TARGET_H - TOP_SOLID - FADE ))
BOTTOM_REST=$(( TARGET_H - FADE ))

# Top Mask: 80px white (full blur) + 30px fade + rest black
magick -size "${TARGET_W}x${TOP_SOLID}" xc:white "$TMPDIR/mask_top_solid.png"
magick -size "${TARGET_W}x${FADE}" gradient:white-black "$TMPDIR/mask_top_fade.png"
magick -size "${TARGET_W}x${TOP_REST}" xc:black "$TMPDIR/mask_top_rest.png"
magick "$TMPDIR/mask_top_solid.png" "$TMPDIR/mask_top_fade.png" "$TMPDIR/mask_top_rest.png" -append "$TMPDIR/mask_top.png"

# Bottom Mask: rest black + 30px fade
magick -size "${TARGET_W}x${BOTTOM_REST}" xc:black "$TMPDIR/mask_bottom_rest.png"
magick -size "${TARGET_W}x${FADE}" gradient:black-white "$TMPDIR/mask_bottom_fade.png"
magick "$TMPDIR/mask_bottom_rest.png" "$TMPDIR/mask_bottom_fade.png" -append "$TMPDIR/mask_bottom.png"

# Left Mask: 30px fade on left edge
magick -size "${FADE}x${TARGET_H}" -define gradient:direction=east gradient:white-black "$TMPDIR/mask_left_fade.png"
magick "$TMPDIR/mask_left_fade.png" -background black -extent "${TARGET_W}x${TARGET_H}" "$TMPDIR/mask_left.png"

# Right Mask: 30px fade on right edge
magick -size "${FADE}x${TARGET_H}" -define gradient:direction=west gradient:white-black "$TMPDIR/mask_right_fade.png"
magick "$TMPDIR/mask_right_fade.png" -gravity east -background black -extent "${TARGET_W}x${TARGET_H}" "$TMPDIR/mask_right.png"

echo "Compositing masks together..."
magick "$TMPDIR/mask_top.png" "$TMPDIR/mask_bottom.png" -compose Screen -composite \
       "$TMPDIR/mask_left.png" -compose Screen -composite \
       "$TMPDIR/mask_right.png" -compose Screen -composite \
       "$TMPDIR/final_mask.png"

echo "Processing blurred background..."
magick "$WORKING_FILE" -blur 0x25 "$TMPDIR/fully_blurred.png"

echo "Applying final compositing..."
magick "$WORKING_FILE" "$TMPDIR/fully_blurred.png" "$TMPDIR/final_mask.png" -composite "$OUTPUT"

# --- 7. Generate Lockscreen Variant ---
OUTPUT_LOCK="${OUTPUT%.*}_lock.${OUTPUT##*.}"
echo "Generating matching Swaylock background..."
magick "$WORKING_FILE" -blur 0x40 -fill "#1a1b26" -colorize 60% -resize "${TARGET_W}x${TARGET_H}" "$OUTPUT_LOCK"

# Cleanup is handled automatically by the EXIT trap

echo "==========================================="
echo "Done! Generated files:"
echo "1) Desktop:    $OUTPUT"
echo "2) Lockscreen: $OUTPUT_LOCK"
echo "==========================================="
