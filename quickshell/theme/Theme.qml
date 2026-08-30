pragma Singleton
import QtQuick

QtObject {
    // Tokyo Night palette
    readonly property color bg:             "#1a1b26"
    readonly property color bgDark:         "#16161e"
    readonly property color bgLight:        "#24283b"
    readonly property color surface:        "#2f3549"
    readonly property color surfaceVariant: "#3b4261"
    readonly property color fg:             "#c0caf5"
    readonly property color fgDim:          "#9aa5ce"
    readonly property color fgMuted:        "#565f89"

    // Hatsune Miku primary accents
    readonly property color accent:         "#39c5bb"
    readonly property color accentGlow:     "#33e0e0"
    readonly property color mikuPink:       "#e35885"
    readonly property color mikuDark:       "#134c48"

    // Semantic colors
    readonly property color blue:           "#7aa2f7"
    readonly property color purple:         "#bb9af7"
    readonly property color red:            "#f7768e"
    readonly property color orange:         "#ff9e64"
    readonly property color yellow:         "#e0af68"
    readonly property color green:          "#73daca"

    // Typography
    readonly property string fontFamily:     "FiraCode Nerd Font"
    readonly property string fontFamilySans: "IBM Plex Sans"
    readonly property int    fontSizeSmall:  14
    readonly property int    fontSize:       18
    readonly property int    fontSizeLarge:  22
    readonly property int    fontWeight:     Font.DemiBold
    readonly property int    fontWeightBold: Font.Bold

    // Geometry
    readonly property bool   showClipboardOnBar: false
    readonly property int    barHeight:          38
    readonly property int    radius:             11
    readonly property int    radiusSmall:        7
    readonly property int    radiusLarge:        14
    readonly property int    borderWidth:        2
    readonly property int    outerGap:           0
    readonly property int    moduleSpacing:      6
    readonly property int    compactPillSize:    barHeight
    readonly property int    pillPaddingHoriz:   14
    readonly property int    compactPaddingLeft: 4
    readonly property int    compactPaddingRight: 8
    readonly property real   pillAlpha:          1.0

    // Standardized Motion & Transition Tokens
    readonly property int    durationFast:       100
    readonly property int    durationMedium:     160
    readonly property int    durationSlow:       240
    readonly property var    easingEnter:        [0.05, 0.7, 0.1, 1.0]
    readonly property var    easingExit:         [0.3, 0.0, 0.8, 0.15]
    readonly property int    easingDecelerate:   Easing.OutCubic
    readonly property int    easingEmphasized:   Easing.OutCubic
}
