#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/v4l2_watch"
SRC="$DIR/v4l2_watch.c"

# Auto-compile if binary is missing or source was updated
if [ ! -x "$BIN" ] || [ "$SRC" -nt "$BIN" ]; then
    gcc -O2 -Wall "$SRC" -o "$BIN" 2>/dev/null
fi

exec "$BIN" "$@"
