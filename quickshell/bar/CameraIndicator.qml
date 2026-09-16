import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    property bool isV4l2Active: false
    property var v4l2Paths: [
        "/sys/class/video4linux/video0/device/../power/runtime_status",
        "/sys/class/video4linux/video2/device/../power/runtime_status"
    ]

    // One-shot scan on startup to discover all V4L2 USB camera power paths (0 continuous background daemons)
    Process {
        id: scanProc
        command: ["sh", "-c", "realpath /sys/class/video4linux/video*/device/../power/runtime_status 2>/dev/null | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    root.v4l2Paths = text.trim().split("\n").filter(Boolean)
                }
            }
        }
    }

    Component.onCompleted: scanProc.running = true

    Instantiator {
        id: v4l2Views
        model: root.v4l2Paths
        delegate: FileView {
            required property string modelData
            path: modelData
            printErrors: false
        }
    }

    // In-process Qt timer checking USB hardware power state (catches direct V4L2: Chrome, OBS, OpenCV, etc.)
    Timer {
        interval: 600
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let active = false
            for (let i = 0; i < v4l2Views.count; i++) {
                const fv = v4l2Views.objectAt(i)
                if (fv) {
                    fv.reload()
                    if (fv.text().trim() === "active") {
                        active = true
                        break
                    }
                }
            }
            root.isV4l2Active = active
        }
    }

    // PipeWire graph monitoring (catches Wayland desktop portal / PipeWire video streams)
    readonly property var allNodes: (Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : []
    PwObjectTracker {
        objects: root.allNodes
    }

    readonly property var videoStreams: allNodes.filter(node => {
        if (!node || !node.isStream) return false
        if (node.properties) {
            const mediaClass = node.properties["media.class"] || ""
            const mediaRole = node.properties["media.role"] || ""
            if (mediaClass === "Stream/Input/Video" || mediaClass.indexOf("Video") !== -1) return true
            if (mediaRole === "Camera") return true
        }
        return false
    })

    readonly property bool isCameraActive: isV4l2Active || videoStreams.length > 0

    // Only show the privacy pill when a camera stream is actively capturing
    collapseWhenEmpty: true
    isEmpty: !isCameraActive

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
