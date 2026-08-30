import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    property bool isCapsOn: false

    Process {
        id: capsProc
        command: [Quickshell.shellPath("scripts/caps_listener.sh")]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var val = data.trim()
                if (val === "1") root.isCapsOn = true
                else if (val === "0") root.isCapsOn = false
            }
        }
    }

    collapseWhenEmpty: true
    isEmpty: !isCapsOn

    implicitWidth: Theme.compactPillSize

    Text {
        anchors.centerIn: parent
        text: "󰪛"
        color: Theme.red
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }
}
