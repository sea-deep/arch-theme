pragma Singleton
import QtQuick

QtObject {
    // Tokyo Night palette
    readonly property color bg:         "#1a1b26"
    readonly property color bgDark:     "#15161e"
    readonly property color bgLight:    "#24283b"
    readonly property color surface:    "#313244"
    readonly property color fg:         "#c0caf5"
    readonly property color fgDim:      "#a9b1d6"
    readonly property color fgMuted:    "#a6adc8"

    // Miku accent
    readonly property color accent:     "#39c5bb"
    readonly property color accentGlow: "#33e0e0"

    // Semantic colors
    readonly property color blue:       "#7aa2f7"
    readonly property color purple:     "#bb9af7"
    readonly property color red:        "#f7768e"
    readonly property color orange:     "#ff9e64"
    readonly property color yellow:     "#e0af68"
    readonly property color green:      "#a6e3a1"

    // Typography
    readonly property string fontFamily:     "FiraCode Nerd Font"
    readonly property string fontFamilySans: "IBM Plex Sans"
    readonly property int    fontSizeSmall:  11
    readonly property int    fontSize:       16
    readonly property int    fontWeight:     600

    // Geometry
    readonly property int    barHeight:      34
    readonly property int    radius:         12
    readonly property int    borderWidth:    2
    readonly property int    outerGap:       2
    readonly property int    moduleSpacing:  4
    readonly property int    compactPillSize: barHeight
    readonly property int    pillPaddingHoriz: 14
    readonly property int    compactPaddingLeft: 4
    readonly property int    compactPaddingRight: 8
    readonly property real   pillAlpha:      1.0
}
