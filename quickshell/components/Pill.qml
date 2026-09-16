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
    clip: false

    color: (hovered && !active && !UiState.hasActiveOverlay) ? Theme.bgLight : "transparent"
    radius: Theme.radius
    border.width: (hovered && !active && !UiState.hasActiveOverlay) ? Theme.borderWidth : 0
    border.color: (hovered && !active && !UiState.hasActiveOverlay) ? Theme.surfaceVariant : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.durationFast }
    }
    Behavior on Layout.preferredWidth {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingDecelerate }
    }

    HoverHandler { id: pillHover }

}
