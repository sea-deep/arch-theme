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

    color: (hovered && !active && !UiState.hasActiveOverlay) ? Theme.bgLight : "transparent"
    radius: Theme.radius
    border.width: 0
    border.color: "transparent"

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    HoverHandler { id: pillHover }

}
