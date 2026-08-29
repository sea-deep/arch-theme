import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property bool hovered: pillHover.hovered
    property bool collapseWhenEmpty: false
    property bool isEmpty: false

    implicitHeight: Theme.barHeight
    Layout.preferredWidth: (collapseWhenEmpty && isEmpty) ? 0 : implicitWidth
    Layout.preferredHeight: Theme.barHeight
    visible: !collapseWhenEmpty || !isEmpty

    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Theme.pillAlpha)
    radius: Theme.radius
    border.width: Theme.borderWidth
    border.color: hovered ? Theme.accentGlow : Theme.bgDark

    Behavior on border.color {
        ColorAnimation { duration: 110 }
    }

    HoverHandler { id: pillHover }

}
