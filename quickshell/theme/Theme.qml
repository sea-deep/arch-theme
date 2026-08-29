pragma Singleton
import QtQuick

QtObject {
    // Miku x Tokyo Night. Neutral surfaces stay blue-black; saturated color
    // is reserved for focus, selection, and status so the shell remains calm.
    readonly property color canvas:          "#10121a"
    readonly property color panel:           "#171925"
    readonly property color surfaceLow:      "#1e2233"
    readonly property color surfaceMedium:   "#272c42"
    readonly property color surfaceHigh:     "#343b58"
    readonly property color outline:         "#3b4261"
    readonly property color outlineSubtle:   "#242a3d"

    readonly property color textPrimary:     "#c8d3f5"
    readonly property color textSecondary:   "#a9b1d6"
    readonly property color textMuted:       "#737da0"

    readonly property color primary:         "#39c5bb"
    readonly property color primaryHover:    "#5bd8cf"
    readonly property color primaryPressed:  "#2aa69e"
    readonly property color primaryContainer:"#173c40"
    readonly property color primaryText:     "#0e2024"

    readonly property color info:            "#7aa2f7"
    readonly property color tertiary:        "#bb9af7"
    readonly property color danger:          "#f7768e"
    readonly property color warning:         "#e0af68"
    readonly property color success:         "#9ece6a"
    readonly property color orange:          "#ff9e64"

    // Compatibility aliases. New code should use the semantic names above.
    readonly property color bg:         panel
    readonly property color bgDark:     canvas
    readonly property color bgLight:    surfaceLow
    readonly property color surface:    surfaceMedium
    readonly property color fg:         textPrimary
    readonly property color fgDim:      textSecondary
    readonly property color fgMuted:    textMuted
    readonly property color accent:     primary
    readonly property color accentGlow: primaryHover
    readonly property color blue:       info
    readonly property color purple:     tertiary
    readonly property color red:        danger
    readonly property color yellow:     warning
    readonly property color green:      success

    // Typography
    readonly property string fontFamily:     "FiraCode Nerd Font"
    readonly property string fontFamilySans: "IBM Plex Sans"
    readonly property int fontSizeTiny:  10
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeBody:  13
    readonly property int fontSize:      16
    readonly property int fontSizeTitle: 16
    readonly property int fontWeight:    Font.DemiBold

    // Geometry
    readonly property int spacingXs:  4
    readonly property int spacingSm:  6
    readonly property int spacingMd:  10
    readonly property int spacingLg:  14
    readonly property int spacingXl:  20
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 9
    readonly property int radiusLarge: 12
    readonly property int radius: radiusLarge
    readonly property int barHeight: 34
    readonly property int borderWidth: 1
    readonly property int outerGap: 2
    readonly property int moduleSpacing: 4
    readonly property int compactPillSize: barHeight
    readonly property int pillPaddingHoriz: 14
    readonly property int compactPaddingLeft: 4
    readonly property int compactPaddingRight: 8
    readonly property real pillAlpha: 1.0

    // Material/Android-style motion: quick response, gentle deceleration, and
    // a faster exit. Curves are cubic-bezier control points plus the endpoint.
    readonly property int motionMicro: 70
    readonly property int motionFast: 110
    readonly property int motionShort: 150
    readonly property int motionMedium: 200
    readonly property int motionLong: 280
    readonly property var easingStandard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var easingEnter: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var easingExit: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
}
