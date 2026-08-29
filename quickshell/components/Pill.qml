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

    color: active ? Theme.primaryContainer
        : (hovered ? Theme.surfaceLow : Theme.panel)
    radius: Theme.radius
    border.width: Theme.borderWidth
    border.color: active ? Theme.primary
        : (hovered ? Theme.primaryHover : Theme.outlineSubtle)

    Behavior on color {
        ColorAnimation { duration: Theme.motionFast }
    }

    Behavior on border.color {
        ColorAnimation { duration: Theme.motionFast }
    }

    HoverHandler { id: pillHover }

}
