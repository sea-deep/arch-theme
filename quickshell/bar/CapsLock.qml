import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    property bool isCapsOn: false
    property var ledPaths: [
        "/sys/class/leds/input3::capslock/brightness",
        "/sys/class/leds/input72::capslock/brightness"
    ]

    // One-shot path scanner on startup to discover all keyboards (built-in and external USB)
    Process {
        id: scanProc
        command: ["sh", "-c", "ls -1 /sys/class/leds/*capslock/brightness 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    root.ledPaths = text.trim().split("\n").filter(Boolean)
                }
            }
        }
    }

    Component.onCompleted: scanProc.running = true

    Instantiator {
        id: ledViews
        model: root.ledPaths
        delegate: FileView {
            required property string modelData
            path: modelData
            printErrors: false
        }
    }

    // Zero-CPU in-process Qt timer (0 background scripts, 0 child processes spawned)
    Timer {
        interval: 400
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let active = false
            for (let i = 0; i < ledViews.count; i++) {
                const fv = ledViews.objectAt(i)
                if (fv) {
                    fv.reload()
                    if (fv.text().trim() === "1") {
                        active = true
                        break
                    }
                }
            }
            root.isCapsOn = active
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
