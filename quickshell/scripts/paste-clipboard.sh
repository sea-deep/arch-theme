#!/usr/bin/env bash
set -euo pipefail

# Robust argument parsing supporting both (type, payload) and legacy order
ARG1="${1:-}"
ARG2="${2:-}"
ARG3="${3:-}"

if [[ "$ARG1" == "image" || "$ARG1" == "text" ]]; then
    TYPE="$ARG1"
    shift
    PAYLOAD="$*"
elif [[ "$ARG3" == "image" || "$ARG3" == "text" ]]; then
    TYPE="$ARG3"
    if [[ "$TYPE" == "image" && -n "$ARG2" && -f "$ARG2" ]]; then
        PAYLOAD="$ARG2"
    else
        PAYLOAD="$ARG1"
    fi
else
    TYPE="text"
    PAYLOAD="$ARG1"
fi

if [[ "$TYPE" == "image" && -f "$PAYLOAD" ]]; then
    mime_type="$(file --brief --mime-type -- "$PAYLOAD" 2>/dev/null || echo "image/png")"
    wl-copy --type "$mime_type" < "$PAYLOAD"
else
    printf "%s" "$PAYLOAD" | wl-copy
    printf "%s" "$PAYLOAD" | wl-copy --primary 2>/dev/null || true
fi

# 120ms focus delay to allow overlay to unmap and active window to regain keyboard focus
sleep 0.12

# Check target window class to send appropriate paste shortcut
active_class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' | tr '[:upper:]' '[:lower:]' || true)"

if [[ "$active_class" == *"kitty"* || "$active_class" == *"foot"* || "$active_class" == *"alacritty"* ]]; then
    # Terminal paste (Ctrl+Shift+V)
    wtype -M ctrl -M shift -k v -m shift -m ctrl 2>/dev/null || wtype -M shift -k Insert -m shift 2>/dev/null || true
else
    # Standard GUI paste (Ctrl+V)
    wtype -M ctrl -k v -m ctrl 2>/dev/null || true
fi
