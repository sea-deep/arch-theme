#!/usr/bin/env bash

set -euo pipefail

image_path="${1:-}"

if [[ -z "$image_path" || ! -f "$image_path" ]]; then
    exit 1
fi

mime_type="$(file --brief --mime-type -- "$image_path")"
wl-copy --type "$mime_type" < "$image_path"
