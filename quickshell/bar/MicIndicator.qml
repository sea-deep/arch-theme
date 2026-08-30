import QtQuick
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    collapseWhenEmpty: true
    isEmpty: !UiState.micActive

    implicitWidth: Theme.compactPillSize

    Text {
        anchors.centerIn: parent
        text: "󰍬"
        color: Theme.orange
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        }
    }
}
