#!/usr/bin/env bash

set -eu

data_dir=""
for candidate in /usr/lib/python*/site-packages/picker/data; do
    if [ -d "$candidate" ]; then
        data_dir="$candidate"
    fi
done

if [ -z "$data_dir" ]; then
    exit 0
fi

for emoji_file in "$data_dir"/emojis_*.csv; do
    if [ -f "$emoji_file" ]; then
        sed -E 's/[[:space:]]*<small>.*<\/small>[[:space:]]*$//' "$emoji_file"
    fi
done
