import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    FileView {
        id: caps1
        path: "/sys/class/leds/input3::capslock/brightness"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    FileView {
        id: caps2
        path: "/sys/class/leds/input5::capslock/brightness"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    readonly property bool isCapsOn: (caps1.text().trim() === "1") || (caps2.text().trim() === "1")

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
