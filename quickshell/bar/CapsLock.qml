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
        running: true
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/capslock.sh"]
        stdout: SplitParser {
            onRead: data => {
                root.isCapsOn = (data.trim() === "1")
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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleProc.running = true
        }
    }

    Process {
        id: toggleProc
        command: ["wtype", "-k", "Caps_Lock"]
    }
}
