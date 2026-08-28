import QtQuick
import "../theme" as Theme

Rectangle {
    id: root

    property bool hovered: false
    property bool collapseWhenEmpty: false
    property bool isEmpty: false

    width: (collapseWhenEmpty && isEmpty) ? 0 : implicitWidth
    height: Theme.barHeight
    visible: width > 0

    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Theme.pillAlpha)
    radius: Theme.radius
    border.width: 2
    border.color: hovered ? Theme.accentGlow : Theme.bgDark

    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }

    Behavior on width {
        NumberAnimation { duration: 200 }
    }

    clip: true
}
