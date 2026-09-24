#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  Zathura Context & Action Menu
#  Provides an interactive, beginner-friendly menu for Zathura via wofi/zenity
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

DBUS_DEST="${1:-}"
DOC_FILE="${2:-}"
PAGE_NUM="${3:-}"

# If DBUS_DEST is empty, attempt to discover the active zathura instance
if [[ -z "$DBUS_DEST" ]]; then
    DBUS_DEST=$(busctl --user list 2>/dev/null | awk '/org\.pwmt\.zathura/ {print $1}' | tail -n 1 || true)
fi

send_cmd() {
    local cmd="$1"
    if [[ -n "$DBUS_DEST" ]]; then
        busctl --user call "$DBUS_DEST" /org/pwmt/zathura org.pwmt.zathura ExecuteCommand s "$cmd" >/dev/null 2>&1 || true
    fi
}

show_cheatsheet() {
    local help_text="<b>Zathura Keyboard Shortcuts & Cheatsheet</b>

<b>Essential Controls:</b>
  • <b>Right-Click / m</b> — Open this Action Menu
  • <b>d</b> — Toggle Eye-Comfort Dark Mode (recolor)
  • <b>r</b> — Reload Document (refresh)
  • <b>Ctrl+O / o</b> — Open Document File Picker
  • <b>Tab / i</b> — Table of Contents / Outline Index
  • <b>Ctrl+F / /</b> — Search / Find in Document
  • <b>Ctrl+P / p</b> — Print Document
  • <b>Shift+D</b> — Dual-Page / Book Layout View
  • <b>q / Ctrl+W</b> — Quit Zathura

<b>Navigation:</b>
  • <b>j / k</b> or <b>Arrow Down / Up</b> — Scroll line by line
  • <b>Space / Shift+Space</b> — Scroll full page down / up
  • <b>Ctrl+D / Ctrl+U</b> — Scroll half page down / up
  • <b>gg / G</b> — Jump to Top / Bottom
  • <b>[number] + G</b> — Jump to page [number] (e.g. 15G)

<b>Zoom & Layout:</b>
  • <b>+ / -</b> or <b>Ctrl + Scroll</b> — Zoom in / out
  • <b>0</b> — Reset zoom to 100%
  • <b>w</b> — Fit to page width
  • <b>f / s</b> — Fit whole page (best-fit)
  • <b>F11</b> — Toggle Fullscreen"

    if command -v zenity >/dev/null 2>&1; then
        zenity --info --title="Zathura Help" --text="$help_text" --width=480 --ok-label="Close" 2>/dev/null &
    else
        notify-send -a "Zathura Help" -i "document-properties" "Zathura Shortcuts" "$help_text" 2>/dev/null || true
    fi
}

OPTIONS=(
    "🌓  Toggle Dark Mode              [ d ]"
    "📂  Open Document...              [ Ctrl+O / o ]"
    "📑  Table of Contents / Outline   [ Tab / i ]"
    "🔍  Find in Document              [ Ctrl+F / / ]"
    "📖  Two-Page (Book) View          [ Shift+D ]"
    "↔️  Fit Page to Width             [ w ]"
    "↕️  Fit Whole Page                [ f / s ]"
    "➕  Zoom In                       [ + / = ]"
    "➖  Zoom Out                      [ - ]"
    "🔄  Reset Zoom (100%)             [ 0 ]"
    "🔁  Reload Document               [ r ]"
    "↷  Rotate Clockwise              [ Ctrl+Right ]"
    "↶  Rotate Counter-Clockwise      [ Ctrl+Left ]"
    "🖨️  Print Document                [ Ctrl+P / p ]"
    "📋  Copy Document File Path       [ y ]"
    "ℹ️  Document Information          [ :info ]"
    "⛶  Toggle Fullscreen              [ F11 ]"
    "❓  Keyboard Shortcuts Help"
    "❌  Quit Zathura                  [ q / Ctrl+W ]"
)

CHOICE=""
if command -v wofi >/dev/null 2>&1; then
    CHOICE=$(printf '%s\n' "${OPTIONS[@]}" | wofi --dmenu \
        --prompt "Zathura Menu" \
        --width 480 \
        --height 520 \
        --insensitive \
        --hide-scroll 2>/dev/null || true)
elif command -v zenity >/dev/null 2>&1; then
    CHOICE=$(printf '%s\n' "${OPTIONS[@]}" | zenity --list \
        --title="Zathura Menu" \
        --column="Action" \
        --width=480 \
        --height=520 2>/dev/null || true)
fi

[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
    *"Toggle Dark Mode"*)
        send_cmd "recolor"
        ;;
    *"Open Document"*)
        send_cmd "file_chooser"
        ;;
    *"Table of Contents"*)
        send_cmd "toggle_index"
        ;;
    *"Find in Document"*)
        send_cmd "feedkeys /"
        ;;
    *"Two-Page"*)
        send_cmd "toggle_page_mode"
        ;;
    *"Fit Page to Width"*)
        send_cmd "adjust_window width"
        ;;
    *"Fit Whole Page"*)
        send_cmd "adjust_window best-fit"
        ;;
    *"Zoom In"*)
        send_cmd "zoom in"
        ;;
    *"Zoom Out"*)
        send_cmd "zoom out"
        ;;
    *"Reset Zoom"*)
        send_cmd "zoom 100"
        ;;
    *"Reload Document"*)
        send_cmd "reload"
        ;;
    *"Rotate Clockwise"*)
        send_cmd "rotate rotate-cw"
        ;;
    *"Rotate Counter-Clockwise"*)
        send_cmd "rotate rotate-ccw"
        ;;
    *"Print Document"*)
        send_cmd "print"
        ;;
    *"Copy Document File Path"*)
        send_cmd "copy_filepath"
        ;;
    *"Document Information"*)
        send_cmd "info"
        ;;
    *"Toggle Fullscreen"*)
        send_cmd "toggle_fullscreen"
        ;;
    *"Keyboard Shortcuts Help"*)
        show_cheatsheet
        ;;
    *"Quit Zathura"*)
        send_cmd "quit"
        ;;
esac
