#!/bin/bash
mkdir -p ~/.config/quickshell/state

STATE_FILE="$HOME/.config/quickshell/state/shaders.json"
SHADER_FILE="$HOME/.config/quickshell/state/current.frag"

# Read existing state if not provided
if [ ! -f "$STATE_FILE" ]; then
    echo '{"comfort":0,"grayscale":0,"vivid":0}' > "$STATE_FILE"
fi

if [ "$1" == "set_all" ]; then
    COMFORT=$2
    GRAYSCALE=$3
    VIVID=$4
    echo "{\"comfort\":$COMFORT,\"grayscale\":$GRAYSCALE,\"vivid\":$VIVID}" > "$STATE_FILE"
else
    COMFORT=$(jq -r '.comfort' "$STATE_FILE")
    GRAYSCALE=$(jq -r '.grayscale' "$STATE_FILE")
    VIVID=$(jq -r '.vivid' "$STATE_FILE")
fi

if [ "$COMFORT" == "0" ] && [ "$GRAYSCALE" == "0" ] && [ "$VIVID" == "0" ]; then
    hyprctl repl "hl.config({ decoration = { screen_shader = '[[EMPTY]]' } })"
    exit 0
fi

# Normalize values (0 to 1)
C_NORM=$(awk "BEGIN {printf \"%.3f\", $COMFORT / 100.0}")
G_NORM=$(awk "BEGIN {printf \"%.3f\", $GRAYSCALE / 100.0}")
V_NORM=$(awk "BEGIN {printf \"%.3f\", $VIVID / 100.0}")

# Generate shader
cat << 'GLSL' > "$SHADER_FILE"
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

    float vivid = VIVID_VAL;
    if (vivid > 0.0) {
        vec3 hsv = rgb2hsv(rgb);
        hsv.y = clamp(hsv.y * (1.0 + vivid), 0.0, 1.0);
        rgb = hsv2rgb(hsv);
    }

    float grayscale = GRAYSCALE_VAL;
    if (grayscale > 0.0) {
        float gray = dot(rgb, vec3(0.299, 0.587, 0.114));
        rgb = mix(rgb, vec3(gray), grayscale);
    }

    float comfort = COMFORT_VAL;
    if (comfort > 0.0) {
        rgb.b = mix(rgb.b, rgb.b * 0.4, comfort);
        rgb.g = mix(rgb.g, rgb.g * 0.8, comfort);
        rgb.r = mix(rgb.r, rgb.r * 1.1, comfort);
        rgb = clamp(rgb, 0.0, 1.0);
    }

    fragColor = vec4(rgb, color.a);
}
GLSL

sed -i "s/VIVID_VAL/$V_NORM/g" "$SHADER_FILE"
sed -i "s/GRAYSCALE_VAL/$G_NORM/g" "$SHADER_FILE"
sed -i "s/COMFORT_VAL/$C_NORM/g" "$SHADER_FILE"

hyprctl repl "hl.config({ decoration = { screen_shader = '$SHADER_FILE' } })"
hyprctl seterror disable
