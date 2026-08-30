import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property bool hovered: pillHover.hovered
    property bool active: false
    property bool collapseWhenEmpty: false
    property bool isEmpty: false

    implicitHeight: Theme.barHeight
    Layout.preferredWidth: (collapseWhenEmpty && isEmpty) ? 0 : implicitWidth
    Layout.preferredHeight: Theme.barHeight
    visible: !collapseWhenEmpty || !isEmpty

    color: active ? Theme.surface : (hovered ? Theme.bgLight : Theme.bgDark)
    radius: Theme.radius
    border.width: Theme.borderWidth
    border.color: (hovered || active) ? Theme.accentGlow : Theme.bgDark

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Behavior on border.color {
        ColorAnimation { duration: 120 }
    }

    HoverHandler { id: pillHover }

}
