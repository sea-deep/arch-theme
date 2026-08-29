import QtQuick
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    collapseWhenEmpty: true
    isEmpty: !UiState.recorderActive

    implicitWidth: Theme.compactPillSize

    Text {
        anchors.centerIn: parent
        text: "●"
        color: Theme.red
        font.family: Theme.fontFamilySans
        font.pixelSize: 14
        font.weight: Font.Bold
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Give immediate feedback. The status probe will restore the dot
            // if the recorder did not actually stop.
            if (UiState.recorderActive)
                UiState.recorderActive = false
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/toggle_recorder.sh"])
        }
    }
}
