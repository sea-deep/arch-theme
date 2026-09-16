#!/usr/bin/env bash
# Copy file or folder path(s) to Wayland clipboard.
# If a path contains whitespace, wrap it in single quotes.

if [[ $# -eq 0 ]]; then
    exit 0
fi

results=()
for path in "$@"; do
    if [[ "$path" =~ [[:space:]] ]]; then
        if [[ "$path" == *"'"* ]]; then
            escaped="${path//\'/\'\\\'\'}"
            results+=("'$escaped'")
        else
            results+=("'$path'")
        fi
    else
        results+=("$path")
    fi
done

if [[ ${#results[@]} -gt 0 ]]; then
    wl-copy -n "${results[*]}"
fi
