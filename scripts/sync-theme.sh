#!/usr/bin/env bash
# ==============================================================================
# scripts/sync-theme.sh
# Monolithic Theme Synchronizer for Tokyo Night Miku Theme
# Source of truth: theme/tokens.json
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOKENS_FILE="$REPO_DIR/theme/tokens.json"

if [ ! -f "$TOKENS_FILE" ]; then
    echo "Error: Tokens file not found at $TOKENS_FILE" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required to parse tokens" >&2
    exit 1
fi

echo "[*] Synchronizing theme across desktop components from $TOKENS_FILE..."

# ------------------------------------------------------------------------------
# Extract tokens via jq
# ------------------------------------------------------------------------------
c_bg="$(jq -r .colors.bg "$TOKENS_FILE")"
c_bgDark="$(jq -r .colors.bgDark "$TOKENS_FILE")"
c_bgLight="$(jq -r .colors.bgLight "$TOKENS_FILE")"
c_surface="$(jq -r .colors.surface "$TOKENS_FILE")"
c_surfaceVariant="$(jq -r .colors.surfaceVariant "$TOKENS_FILE")"
c_fg="$(jq -r .colors.fg "$TOKENS_FILE")"
c_fgDim="$(jq -r .colors.fgDim "$TOKENS_FILE")"
c_fgMuted="$(jq -r .colors.fgMuted "$TOKENS_FILE")"
c_accent="$(jq -r .colors.accent "$TOKENS_FILE")"
c_accentGlow="$(jq -r .colors.accentGlow "$TOKENS_FILE")"
c_mikuPink="$(jq -r .colors.mikuPink "$TOKENS_FILE")"
c_mikuDark="$(jq -r .colors.mikuDark "$TOKENS_FILE")"
c_blue="$(jq -r .colors.blue "$TOKENS_FILE")"
c_purple="$(jq -r .colors.purple "$TOKENS_FILE")"
c_red="$(jq -r .colors.red "$TOKENS_FILE")"
c_orange="$(jq -r .colors.orange "$TOKENS_FILE")"
c_yellow="$(jq -r .colors.yellow "$TOKENS_FILE")"
c_green="$(jq -r .colors.green "$TOKENS_FILE")"

font_family="$(jq -r .typography.fontFamily "$TOKENS_FILE")"
font_family_mono="$(jq -r .typography.fontFamilyMono "$TOKENS_FILE")"
font_weight_code="$(jq -r .typography.fontWeightCode "$TOKENS_FILE")"
font_size_base="$(jq -r .typography.fontSizeBase "$TOKENS_FILE")"
font_size_small="$(jq -r .typography.fontSizeSmall "$TOKENS_FILE")"

icon_theme="$(jq -r .icons.theme "$TOKENS_FILE")"
cursor_theme="$(jq -r .icons.cursorTheme "$TOKENS_FILE")"
cursor_size="$(jq -r .icons.cursorSize "$TOKENS_FILE")"
gtk_theme="$(jq -r .environment.gtkTheme "$TOKENS_FILE")"

hex_to_argb() {
    local h="${1#"#"}"
    echo "#ff${h,,}"
}

hex_to_rgb() {
    local h="${1#"#"}"
    printf "%d,%d,%d" "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# ------------------------------------------------------------------------------
# 1. Generate Qt5 & Qt6 TokyoNight.conf Color Schemes (21 QPalette roles)
# ------------------------------------------------------------------------------
# 0: WindowText, 1: Button, 2: Light, 3: Midlight, 4: Dark, 5: Mid, 6: Text,
# 7: BrightText, 8: ButtonText, 9: Base, 10: Window, 11: Shadow, 12: Highlight,
# 13: HighlightedText, 14: Link, 15: LinkVisited, 16: AlternateBase, 17: NoRole,
# 18: ToolTipBase, 19: ToolTipText, 20: PlaceholderText

active_colors="$(hex_to_argb "$c_fg"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_surfaceVariant"), $(hex_to_argb "$c_surface"), $(hex_to_argb "$c_bgDark"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_fg"), #ffffffff, $(hex_to_argb "$c_fg"), $(hex_to_argb "$c_bgDark"), $(hex_to_argb "$c_bg"), #ff101014, $(hex_to_argb "$c_accent"), $(hex_to_argb "$c_bgDark"), $(hex_to_argb "$c_blue"), $(hex_to_argb "$c_purple"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_bg"), $(hex_to_argb "$c_bg"), $(hex_to_argb "$c_fg"), $(hex_to_argb "$c_fgMuted")"

disabled_colors="$(hex_to_argb "$c_fgMuted"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_surfaceVariant"), $(hex_to_argb "$c_surface"), $(hex_to_argb "$c_bgDark"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_fgMuted"), #ffffffff, $(hex_to_argb "$c_fgMuted"), $(hex_to_argb "$c_bgDark"), $(hex_to_argb "$c_bg"), #ff101014, $(hex_to_argb "$c_mikuDark"), $(hex_to_argb "$c_fgMuted"), $(hex_to_argb "$c_fgMuted"), $(hex_to_argb "$c_fgMuted"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_bg"), $(hex_to_argb "$c_bg"), $(hex_to_argb "$c_fgMuted"), $(hex_to_argb "$c_surfaceVariant")"

inactive_colors="$(hex_to_argb "$c_fgDim"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_surfaceVariant"), $(hex_to_argb "$c_surface"), $(hex_to_argb "$c_bgDark"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_fgDim"), #ffffffff, $(hex_to_argb "$c_fgDim"), $(hex_to_argb "$c_bgDark"), $(hex_to_argb "$c_bg"), #ff101014, $(hex_to_argb "$c_surface"), $(hex_to_argb "$c_fg"), $(hex_to_argb "$c_blue"), $(hex_to_argb "$c_purple"), $(hex_to_argb "$c_bgLight"), $(hex_to_argb "$c_bg"), $(hex_to_argb "$c_bg"), $(hex_to_argb "$c_fgDim"), $(hex_to_argb "$c_fgMuted")"

write_qt_colorscheme() {
    local target="$1"
    mkdir -p "$(dirname "$target")"
    cat << EOF > "$target.tmp"
[ColorScheme]
active_colors=$active_colors
disabled_colors=$disabled_colors
inactive_colors=$inactive_colors
EOF
    mv "$target.tmp" "$target"
}

write_qt_colorscheme "$REPO_DIR/qt5ct/colors/TokyoNight.conf"
write_qt_colorscheme "$REPO_DIR/qt6ct/colors/TokyoNight.conf"

# ------------------------------------------------------------------------------
# 2. Update qt5ct.conf and qt6ct.conf
# ------------------------------------------------------------------------------
write_qt_conf() {
    local target="$1"
    local scheme_path="$2"
    mkdir -p "$(dirname "$target")"
    cat << EOF > "$target.tmp"
[Appearance]
color_scheme_path=$scheme_path
custom_palette=true
icon_theme=$icon_theme
standard_dialogs=default
style=kvantum

[Fonts]
fixed="$font_family_mono,$font_size_base,-1,5,$font_weight_code,0,0,0,0,0"
general="$font_family,$font_size_base,-1,5,$font_weight_code,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOF
    mv "$target.tmp" "$target"
}

write_qt_conf "$REPO_DIR/qt5ct/qt5ct.conf" "$HOME/.local/share/qt5ct/colors/TokyoNight.conf"
write_qt_conf "$REPO_DIR/qt6ct/qt6ct.conf" "$HOME/.local/share/qt6ct/colors/TokyoNight.conf"

# ------------------------------------------------------------------------------
# 3. Generate GTK colors.css (GTK3 and GTK4)
# ------------------------------------------------------------------------------
write_gtk_colors() {
    local target="$1"
    mkdir -p "$(dirname "$target")"
    cat << EOF > "$target.tmp"
/* Monolithic Tokyo Night Miku GTK Colors — Generated by sync-theme.sh */
@define-color theme_bg_color $c_bg;
@define-color theme_fg_color $c_fg;
@define-color theme_base_color $c_bgDark;
@define-color theme_text_color $c_fg;
@define-color theme_selected_bg_color $c_accent;
@define-color theme_selected_fg_color $c_bgDark;

@define-color accent_color $c_accent;
@define-color accent_bg_color $c_accent;
@define-color accent_fg_color $c_bgDark;

@define-color destructive_color $c_red;
@define-color destructive_bg_color $c_red;
@define-color destructive_fg_color $c_bgDark;

@define-color success_color $c_green;
@define-color success_bg_color $c_green;
@define-color success_fg_color $c_bgDark;

@define-color warning_color $c_yellow;
@define-color warning_bg_color $c_yellow;
@define-color warning_fg_color $c_bgDark;

@define-color error_color $c_red;
@define-color error_bg_color $c_red;
@define-color error_fg_color $c_bgDark;

@define-color window_bg_color $c_bg;
@define-color window_fg_color $c_fg;

@define-color view_bg_color $c_bgDark;
@define-color view_fg_color $c_fg;

@define-color headerbar_bg_color $c_bgDark;
@define-color headerbar_fg_color $c_fg;
@define-color headerbar_border_color transparent;

@define-color sidebar_bg_color $c_bgDark;
@define-color sidebar_fg_color $c_fg;

@define-color card_bg_color $c_bgLight;
@define-color card_fg_color $c_fg;
@define-color card_shade_color rgba(0, 0, 0, 0.36);

@define-color popover_bg_color $c_bgLight;
@define-color popover_fg_color $c_fg;

@define-color dialog_bg_color $c_bg;
@define-color dialog_fg_color $c_fg;

@define-color borders $c_surface;
EOF
    mv "$target.tmp" "$target"
}

write_gtk_colors "$REPO_DIR/gtk-3.0/colors.css"
write_gtk_colors "$REPO_DIR/gtk-4.0/colors.css"

# ------------------------------------------------------------------------------
# 4. Update GTK settings.ini (GTK3 and GTK4)
# ------------------------------------------------------------------------------
write_gtk3_settings() {
    local target="$REPO_DIR/gtk-3.0/settings.ini"
    cat << EOF > "$target.tmp"
[Settings]
gtk-application-prefer-dark-theme=true
gtk-button-images=true
gtk-cursor-blink=true
gtk-cursor-blink-time=1000
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=$cursor_size
gtk-decoration-layout=:close
gtk-enable-animations=true
gtk-font-name=$font_family SmBld $font_size_base
gtk-icon-theme-name=$icon_theme
gtk-menu-images=true
gtk-modules=colorreload-gtk-module:window-decorations-gtk-module
gtk-primary-button-warps-slider=true
gtk-sound-theme-name=Pop
gtk-theme-name=$gtk_theme
gtk-toolbar-style=3
gtk-xft-dpi=98304
EOF
    mv "$target.tmp" "$target"
}

write_gtk4_settings() {
    local target="$REPO_DIR/gtk-4.0/settings.ini"
    cat << EOF > "$target.tmp"
[Settings]
gtk-application-prefer-dark-theme=true
gtk-cursor-blink=true
gtk-cursor-blink-time=1000
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=$cursor_size
gtk-decoration-layout=:close
gtk-enable-animations=true
gtk-font-name=$font_family SmBld $font_size_base
gtk-icon-theme-name=$icon_theme
gtk-primary-button-warps-slider=true
gtk-sound-theme-name=Pop
gtk-theme-name=$gtk_theme
gtk-xft-dpi=98304
EOF
    mv "$target.tmp" "$target"
}

write_gtk3_settings
write_gtk4_settings

# ------------------------------------------------------------------------------
# 5. Update xsettingsd.conf
# ------------------------------------------------------------------------------
write_xsettingsd() {
    local target="$REPO_DIR/xsettingsd/xsettingsd.conf"
    mkdir -p "$(dirname "$target")"
    cat << EOF > "$target.tmp"
Net/CursorBlinkTime 1000
Net/CursorBlink 1
Gdk/UnscaledDPI 98304
Gdk/WindowScalingFactor 1
Gtk/EnableAnimations 1
Gtk/DecorationLayout ":close"
Net/ThemeName "$gtk_theme"
Gtk/PrimaryButtonWarpsSlider 1
Gtk/ToolbarStyle 3
Gtk/MenuImages 1
Gtk/ButtonImages 1
Gtk/CursorThemeSize $cursor_size
Gtk/CursorThemeName "$cursor_theme"
Net/SoundThemeName "Pop"
Net/IconThemeName "$icon_theme"
Gtk/FontName "$font_family SmBld $font_size_base"
EOF
    mv "$target.tmp" "$target"
}

write_xsettingsd

# ------------------------------------------------------------------------------
# 6. Update kdeglobals
# ------------------------------------------------------------------------------
write_kdeglobals() {
    local target="$REPO_DIR/kdeglobals"
    local rgb_bg="$(hex_to_rgb "$c_bg")"
    local rgb_bgDark="$(hex_to_rgb "$c_bgDark")"
    local rgb_bgLight="$(hex_to_rgb "$c_bgLight")"
    local rgb_surface="$(hex_to_rgb "$c_surface")"
    local rgb_fg="$(hex_to_rgb "$c_fg")"
    local rgb_fgDim="$(hex_to_rgb "$c_fgDim")"
    local rgb_fgMuted="$(hex_to_rgb "$c_fgMuted")"
    local rgb_accent="$(hex_to_rgb "$c_accent")"
    local rgb_blue="$(hex_to_rgb "$c_blue")"
    local rgb_purple="$(hex_to_rgb "$c_purple")"
    local rgb_red="$(hex_to_rgb "$c_red")"
    local rgb_yellow="$(hex_to_rgb "$c_yellow")"
    local rgb_green="$(hex_to_rgb "$c_green")"

    cat << EOF > "$target.tmp"
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=$rgb_surface
BackgroundNormal=$rgb_bgLight
DecorationFocus=$rgb_accent
DecorationHover=$rgb_accent
ForegroundActive=$rgb_accent
ForegroundInactive=$rgb_fgMuted
ForegroundLink=$rgb_blue
ForegroundNegative=$rgb_red
ForegroundNeutral=$rgb_yellow
ForegroundNormal=$rgb_fg
ForegroundPositive=$rgb_green
ForegroundVisited=$rgb_purple

[Colors:Complementary]
BackgroundAlternate=$rgb_bgLight
BackgroundNormal=$rgb_bg
DecorationFocus=$rgb_accent
DecorationHover=$rgb_accent
ForegroundActive=$rgb_accent
ForegroundInactive=$rgb_fgMuted
ForegroundLink=$rgb_blue
ForegroundNegative=$rgb_red
ForegroundNeutral=$rgb_yellow
ForegroundNormal=$rgb_fg
ForegroundPositive=$rgb_green
ForegroundVisited=$rgb_purple

[Colors:Header]
BackgroundAlternate=$rgb_bgLight
BackgroundNormal=$rgb_bg
DecorationFocus=$rgb_accent
DecorationHover=$rgb_accent
ForegroundActive=$rgb_accent
ForegroundInactive=$rgb_fgMuted
ForegroundLink=$rgb_blue
ForegroundNegative=$rgb_red
ForegroundNeutral=$rgb_yellow
ForegroundNormal=$rgb_fg
ForegroundPositive=$rgb_green
ForegroundVisited=$rgb_purple

[Colors:Selection]
BackgroundAlternate=$rgb_accent
BackgroundNormal=$rgb_accent
DecorationFocus=$rgb_accent
DecorationHover=$rgb_accent
ForegroundActive=$rgb_bgDark
ForegroundInactive=$rgb_bgDark
ForegroundLink=$rgb_blue
ForegroundNegative=$rgb_red
ForegroundNeutral=$rgb_yellow
ForegroundNormal=$rgb_bgDark
ForegroundPositive=$rgb_green
ForegroundVisited=$rgb_purple

[Colors:Tooltip]
BackgroundAlternate=$rgb_bgLight
BackgroundNormal=$rgb_bg
DecorationFocus=$rgb_accent
DecorationHover=$rgb_accent
ForegroundActive=$rgb_accent
ForegroundInactive=$rgb_fgMuted
ForegroundLink=$rgb_blue
ForegroundNegative=$rgb_red
ForegroundNeutral=$rgb_yellow
ForegroundNormal=$rgb_fg
ForegroundPositive=$rgb_green
ForegroundVisited=$rgb_purple

[Colors:View]
BackgroundAlternate=$rgb_bgLight
BackgroundNormal=$rgb_bgDark
DecorationFocus=$rgb_accent
DecorationHover=$rgb_accent
ForegroundActive=$rgb_accent
ForegroundInactive=$rgb_fgMuted
ForegroundLink=$rgb_blue
ForegroundNegative=$rgb_red
ForegroundNeutral=$rgb_yellow
ForegroundNormal=$rgb_fg
ForegroundPositive=$rgb_green
ForegroundVisited=$rgb_purple

[Colors:Window]
BackgroundAlternate=$rgb_bgLight
BackgroundNormal=$rgb_bg
DecorationFocus=$rgb_accent
DecorationHover=$rgb_accent
ForegroundActive=$rgb_accent
ForegroundInactive=$rgb_fgMuted
ForegroundLink=$rgb_blue
ForegroundNegative=$rgb_red
ForegroundNeutral=$rgb_yellow
ForegroundNormal=$rgb_fg
ForegroundPositive=$rgb_green
ForegroundVisited=$rgb_purple

[General]
AccentColor=$rgb_accent
ColorScheme=TokyoNight
Name=Tokyo Night Miku
TerminalApplication=kitty
TerminalService=kitty.desktop
UseSystemBell=true
XftAntialias=true
XftHintStyle=hintfull
XftSubPixel=rgb
fixed=$font_family_mono,$font_size_base,-1,5,$font_weight_code,0,0,0,0,0
font=$font_family,$font_size_base,-1,5,$font_weight_code,0,0,0,0,0
menuFont=$font_family,$font_size_base,-1,5,$font_weight_code,0,0,0,0,0
smallestReadableFont=$font_family,$font_size_small,-1,5,$font_weight_code,0,0,0,0,0
toolBarFont=$font_family,$font_size_base,-1,5,$font_weight_code,0,0,0,0,0

[Icons]
Theme=$icon_theme

[KDE]
AnimationDurationFactor=1.0
SingleClick=true
contrast=4
frameContrast=0.2

[KFileDialog Settings]
Allow Expansion=false
Automatically select filename extension=true
Breadcrumb Navigation=true
Decoration position=2
Show Full Path=false
Show Inline Previews=true
Show Preview=false
Show Speedbar=true
Show hidden files=false
Sort by=Name
Sort reversed=false
View Mode=Detail

[WM]
activeBackground=$rgb_bg
activeBlend=$rgb_bg
activeForeground=$rgb_fg
inactiveBackground=$rgb_bgDark
inactiveBlend=$rgb_bgDark
inactiveForeground=$rgb_fgDim
EOF
    mv "$target.tmp" "$target"
}

write_kdeglobals

# ------------------------------------------------------------------------------
# 7. Update Kvantum Tokyo Night GeneralColors
# ------------------------------------------------------------------------------
update_kvantum() {
    local kvconfig="$REPO_DIR/Kvantum/Kvantum-Tokyo-Night/Kvantum-Tokyo-Night.kvconfig"
    if [ -f "$kvconfig" ]; then
        sed -i \
            -e "s/^highlight\.color=.*/highlight.color=${c_accent}/" \
            -e "s/^window\.color=.*/window.color=${c_bg}/" \
            -e "s/^base\.color=.*/base.color=${c_bgDark}/" \
            -e "s/^alt\.base\.color=.*/alt.base.color=${c_bgLight}/" \
            -e "s/^button\.color=.*/button.color=${c_bgLight}/" \
            -e "s/^highlight\.text\.color=.*/highlight.text.color=${c_bgDark}/" \
            -e "s/^disabled\.text\.color=.*/disabled.text.color=${c_fgMuted}/" \
            -e "s/^link\.color=.*/link.color=${c_blue}/" \
            -e "s/^link\.visited\.color=.*/link.visited.color=${c_purple}/" \
            -e "s/^progress\.indicator\.text\.color=.*/progress.indicator.text.color=${c_bgDark}/" \
            "$kvconfig"
    fi
}

update_kvantum

# ------------------------------------------------------------------------------
# 8. Manage Symlinks in User Home
# ------------------------------------------------------------------------------
ensure_symlink() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ -L "$dest" ]; then
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        mv "$dest" "${dest}.bak"
    fi
    ln -sf "$src" "$dest"
}

ensure_symlink "$REPO_DIR/qt5ct/colors/TokyoNight.conf" "$HOME/.local/share/qt5ct/colors/TokyoNight.conf"
ensure_symlink "$REPO_DIR/qt6ct/colors/TokyoNight.conf" "$HOME/.local/share/qt6ct/colors/TokyoNight.conf"
ensure_symlink "$REPO_DIR/xsettingsd/xsettingsd.conf" "$HOME/.config/xsettingsd/xsettingsd.conf"

echo "[+] Theme synchronization complete!"
