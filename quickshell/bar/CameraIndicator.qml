import QtQuick
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    collapseWhenEmpty: true
    isEmpty: !UiState.cameraActive

    implicitWidth: Theme.compactPillSize

    Text {
        anchors.centerIn: parent
        text: "󰄀"
        color: Theme.green
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }
}
