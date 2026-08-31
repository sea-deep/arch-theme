#!/usr/bin/env bash
set -euo pipefail

CHAR="${1:-}"
if [[ -z "$CHAR" ]]; then
    exit 0
fi

# Copy to both standard clipboard and primary selection
wl-copy "$CHAR"
wl-copy --primary "$CHAR" 2>/dev/null || true

# Give active window focus time to settle after Quickshell yields focus
sleep 0.05

# Send Ctrl+V paste keypress via wtype
wtype -M ctrl -k v -m ctrl 2>/dev/null || true
