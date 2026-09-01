import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    property bool isCapsOn: false

    FileView {
        id: caps1
        path: "/sys/class/leds/input3::capslock/brightness"
        printErrors: false
    }

    FileView {
        id: caps2
        path: "/sys/class/leds/input5::capslock/brightness"
        printErrors: false
    }

    // Zero-CPU in-process Qt timer (0 background scripts, 0 child processes spawned)
    Timer {
        interval: 200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            caps1.reload()
            caps2.reload()
            var on1 = (caps1.text().trim() === "1")
            var on2 = (caps2.text().trim() === "1")
            root.isCapsOn = on1 || on2
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
        onClicked: toggleProc.running = true
    }

    Process {
        id: toggleProc
        command: ["wtype", "-k", "Caps_Lock"]
    }
}
