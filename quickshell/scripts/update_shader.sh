#!/bin/bash
STATE_DIR="$HOME/.config/quickshell/state"
mkdir -p "$STATE_DIR"

STATE_FILE="$STATE_DIR/shaders.json"
TARGET_FLAG="$STATE_DIR/target_slot"

# Read existing state if not provided
if [ ! -f "$STATE_FILE" ]; then
    echo '{"comfort":0,"grayscale":0,"vivid":0}' > "$STATE_FILE"
fi

if [ "$1" == "set_all" ]; then
    COMFORT=${2:-0}
    GRAYSCALE=${3:-0}
    VIVID=${4:-0}
    echo "{\"comfort\":$COMFORT,\"grayscale\":$GRAYSCALE,\"vivid\":$VIVID}" > "$STATE_FILE"
else
    COMFORT=$(jq -r '.comfort // 0' "$STATE_FILE" 2>/dev/null || echo 0)
    GRAYSCALE=$(jq -r '.grayscale // 0' "$STATE_FILE" 2>/dev/null || echo 0)
    VIVID=$(jq -r '.vivid // 0' "$STATE_FILE" 2>/dev/null || echo 0)
fi

if [ "$COMFORT" == "0" ] && [ "$GRAYSCALE" == "0" ] && [ "$VIVID" == "0" ]; then
    hyprctl eval "hl.config({ decoration = { screen_shader = '' } })" 2>/dev/null || true
    hyprctl repl "hl.config({ decoration = { screen_shader = '' } })" 2>/dev/null || true
    hyprctl seterror disable 2>/dev/null || true
    exit 0
fi

# Alternate between slot a and slot b so Hyprland detects the file path change immediately
CUR_SLOT=$(cat "$TARGET_FLAG" 2>/dev/null || echo "b")
if [ "$CUR_SLOT" == "a" ]; then
    NEXT_SLOT="b"
else
    NEXT_SLOT="a"
fi
echo "$NEXT_SLOT" > "$TARGET_FLAG"

SHADER_FILE="$STATE_DIR/shader_${NEXT_SLOT}.frag"
TMP_FILE="$STATE_DIR/shader_${NEXT_SLOT}.frag.tmp"

# Normalize values (0.0 to 1.0)
C_NORM=$(awk "BEGIN {printf \"%.4f\", $COMFORT / 100.0}")
G_NORM=$(awk "BEGIN {printf \"%.4f\", $GRAYSCALE / 100.0}")
V_NORM=$(awk "BEGIN {printf \"%.4f\", $VIVID / 100.0}")

# Generate shader atomically
cat << GLSL > "$TMP_FILE"
#version 300 es
precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec4 color = texture(tex, v_texcoord);
    vec3 rgb = color.rgb;

    float vivid = $V_NORM;
    if (vivid > 0.0) {
        vec3 hsv = rgb2hsv(rgb);
        hsv.y = clamp(hsv.y * (1.0 + vivid), 0.0, 1.0);
        rgb = hsv2rgb(hsv);
    }

    float grayscale = $G_NORM;
    if (grayscale > 0.0) {
        float gray = dot(rgb, vec3(0.299, 0.587, 0.114));
        rgb = mix(rgb, vec3(gray), grayscale);
    }

    float comfort = $C_NORM;
    if (comfort > 0.0) {
        rgb.b = mix(rgb.b, rgb.b * 0.4, comfort);
        rgb.g = mix(rgb.g, rgb.g * 0.8, comfort);
        rgb.r = mix(rgb.r, rgb.r * 1.1, comfort);
        rgb = clamp(rgb, 0.0, 1.0);
    }

    fragColor = vec4(rgb, color.a);
}
GLSL

mv -f "$TMP_FILE" "$SHADER_FILE"

hyprctl eval "hl.config({ decoration = { screen_shader = '$SHADER_FILE' } })" 2>/dev/null || true
hyprctl repl "hl.config({ decoration = { screen_shader = '$SHADER_FILE' } })" 2>/dev/null || true
hyprctl seterror disable 2>/dev/null || true
