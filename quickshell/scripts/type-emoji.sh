#!/bin/bash
CHAR="$1"

# Copy to both standard clipboard and primary selection
wl-copy "$CHAR"
wl-copy --primary "$CHAR" 2>/dev/null || true

# Small delay to allow Quickshell overlay to close and target window to regain focus
sleep 0.12

# Send Ctrl+V paste keypress
wtype -M ctrl -k v -m ctrl 2>/dev/null || true
