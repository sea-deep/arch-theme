#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-text}"
shift || true
PAYLOAD="$*"

if [[ "$TYPE" == "image" ]]; then
    if [[ -z "$PAYLOAD" || ! -f "$PAYLOAD" ]]; then
        exit 1
    fi
    mime_type="$(file --brief --mime-type -- "$PAYLOAD" 2>/dev/null || echo "image/png")"
    wl-copy --type "$mime_type" < "$PAYLOAD"
else
    wl-copy "$PAYLOAD"
    wl-copy --primary "$PAYLOAD" 2>/dev/null || true
fi

# Small delay to allow Quickshell overlay to close and target window to regain focus
sleep 0.04

# Simulate Ctrl+V paste keypress via wtype
wtype -M ctrl -k v -m ctrl 2>/dev/null || true
