import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    // 1. Check native PipeWire graph for active video capture streams
    readonly property var videoStreams: {
        if (!Pipewire.nodes || !Pipewire.nodes.values) return []
        return Pipewire.nodes.values.filter(node => {
            if (!node) return false
            if (node.isStream && node.audio === null) return true
            if (node.properties && node.properties["media.class"] === "Stream/Input/Video") return true
            return false
        })
    }

    // 2. Check Linux kernel USB camera power runtime status
    FileView {
        id: cam0
        path: "/sys/class/video4linux/video0/device/../power/runtime_status"
        watchChanges: true
    }

    FileView {
        id: cam2
        path: "/sys/class/video4linux/video2/device/../power/runtime_status"
        watchChanges: true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cam0.reload()
            cam2.reload()
        }
    }

    readonly property bool isSysfsActive: cam0.text().trim() === "active" || cam2.text().trim() === "active"
    readonly property bool isCameraActive: isSysfsActive || videoStreams.length > 0

    // Only show the privacy pill when a camera stream is actively capturing
    collapseWhenEmpty: true
    isEmpty: !isCameraActive

    implicitWidth: Theme.compactPillSize

    PwObjectTracker {
        objects: root.videoStreams
    }

    Text {
        anchors.centerIn: parent
        text: "󰄀"
        color: Theme.green
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }
}
