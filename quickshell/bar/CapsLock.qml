import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    FileView {
        id: internalCaps
        path: "/sys/class/leds/input3::capslock/brightness"
        watchChanges: true
    }

    FileView {
        id: externalCaps
        path: "/sys/class/leds/input8::capslock/brightness"
        watchChanges: true
    }

    readonly property bool isCapsOn: internalCaps.text().trim() === "1" || externalCaps.text().trim() === "1"

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
