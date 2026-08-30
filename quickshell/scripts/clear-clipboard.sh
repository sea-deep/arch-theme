#!/usr/bin/env bash
set -euo pipefail

wl-copy --clear 2>/dev/null || true
wl-copy --primary --clear 2>/dev/null || true
clipse -clear 2>/dev/null || true
echo '{"clipboardHistory":[]}' > "$HOME/.config/clipse/clipboard_history.json"
