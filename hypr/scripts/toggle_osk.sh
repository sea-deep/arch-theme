#!/usr/bin/env bash
# ==============================================================================
# hypr/scripts/toggle_osk.sh
# Toggle wvkbd lightweight on-screen virtual keyboard with sea-deep palette
# Source of truth: theme/tokens.json
# ==============================================================================
set -euo pipefail

if pgrep -x "wvkbd-mobintl" > /dev/null 2>&1 || pgrep -x "wvkbd-deskintl" > /dev/null 2>&1 || pgrep -x "wvkbd" > /dev/null 2>&1; then
    pkill -x "wvkbd-mobintl" 2>/dev/null || true
    pkill -x "wvkbd-deskintl" 2>/dev/null || true
    pkill -x "wvkbd" 2>/dev/null || true
    exit 0
fi

# Locate binary
WVKBD="$(command -v wvkbd-mobintl 2>/dev/null || command -v wvkbd-deskintl 2>/dev/null || command -v wvkbd 2>/dev/null || echo "$HOME/.local/bin/wvkbd-mobintl")"
if ! command -v "$WVKBD" >/dev/null 2>&1 && [ ! -x "$WVKBD" ]; then
    echo "Error: wvkbd binary not found" >&2
    exit 1
fi

# Locate design tokens
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOKENS_FILE="${TOKENS_FILE:-$REPO_DIR/theme/tokens.json}"

# Fallback default tokens (sea-deep theme)
C_BG="1a1b26"
C_FG="24283b"
C_FG_SP="1f2335"
C_PRESS="39c5bb"
C_PRESS_SP="39c5bb"
C_TEXT="c0caf5"
C_TEXT_SP="7aa2f7"
C_TEXT_PRESS="1a1b26"
FONT_FAMILY="IBM Plex Sans"
FONT_WEIGHT="SemiBold"
FONT_SIZE=15
OSK_RADIUS=8
OSK_HEIGHT=280

# Dynamically extract tokens from theme/tokens.json if present
if [ -f "$TOKENS_FILE" ] && command -v jq >/dev/null 2>&1; then
    IFS=$'\t' read -r t_bg t_fg t_fg_sp t_press t_press_sp t_text t_text_sp t_text_press t_font_fam t_font_weight t_radius t_height t_font_size < <(
        jq -r '[
            (.colors.bg // "#1a1b26"),
            (.colors.bgLight // "#24283b"),
            (.osk.fgSpecial // .colors.bgDark // "#1f2335"),
            (.colors.accent // "#39c5bb"),
            (.colors.accent // "#39c5bb"),
            (.colors.fg // "#c0caf5"),
            (.colors.blue // "#7aa2f7"),
            (.colors.bg // "#1a1b26"),
            (.typography.fontFamily // "IBM Plex Sans"),
            (.typography.fontWeight // "SemiBold"),
            ((.osk.radius // .geometry.radiusSmall // 8) | tostring),
            ((.osk.height // 280) | tostring),
            ((.osk.fontSize // 15) | tostring)
        ] | @tsv' "$TOKENS_FILE" 2>/dev/null
    ) || true

    [ -n "${t_bg:-}" ] && C_BG="${t_bg#"#"}"
    [ -n "${t_fg:-}" ] && C_FG="${t_fg#"#"}"
    [ -n "${t_fg_sp:-}" ] && C_FG_SP="${t_fg_sp#"#"}"
    [ -n "${t_press:-}" ] && C_PRESS="${t_press#"#"}"
    [ -n "${t_press_sp:-}" ] && C_PRESS_SP="${t_press_sp#"#"}"
    [ -n "${t_text:-}" ] && C_TEXT="${t_text#"#"}"
    [ -n "${t_text_sp:-}" ] && C_TEXT_SP="${t_text_sp#"#"}"
    [ -n "${t_text_press:-}" ] && C_TEXT_PRESS="${t_text_press#"#"}"
    [ -n "${t_font_fam:-}" ] && FONT_FAMILY="$t_font_fam"
    [ -n "${t_font_weight:-}" ] && FONT_WEIGHT="$t_font_weight"
    [ -n "${t_radius:-}" ] && OSK_RADIUS="$t_radius"
    [ -n "${t_height:-}" ] && OSK_HEIGHT="$t_height"
    [ -n "${t_font_size:-}" ] && FONT_SIZE="$t_font_size"
fi

"$WVKBD" \
    -L "$OSK_HEIGHT" \
    -R "$OSK_RADIUS" \
    --no-popup \
    --bg "$C_BG" \
    --fg "$C_FG" \
    --fg-sp "$C_FG_SP" \
    --press "$C_PRESS" \
    --press-sp "$C_PRESS_SP" \
    --text "$C_TEXT" \
    --text-sp "$C_TEXT_SP" \
    --text-press "$C_TEXT_PRESS" \
    --fn "$FONT_FAMILY $FONT_WEIGHT $FONT_SIZE" \
    > /dev/null 2>&1 &
