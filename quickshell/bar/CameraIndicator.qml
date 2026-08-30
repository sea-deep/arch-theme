import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    // Pure event-driven PipeWire graph monitoring (0% CPU, 0 timers, 0 background files)
    readonly property var allNodes: Pipewire.nodes && Pipewire.nodes.values ? Pipewire.nodes.values : []
    readonly property var videoStreams: allNodes.filter(node => {
        if (!node) return false
        if (node.isStream && node.audio === null) return true
        if (node.properties) {
            const mediaClass = node.properties["media.class"] || ""
            const mediaRole = node.properties["media.role"] || ""
            if (mediaClass === "Stream/Input/Video" || mediaClass.indexOf("Video") !== -1 && node.isStream) return true
            if (mediaRole === "Camera" && node.isStream) return true
        }
        return false
    })

    readonly property bool isCameraActive: videoStreams.length > 0

    // Only show the privacy pill when a camera stream is actively capturing
    collapseWhenEmpty: true
    isEmpty: !isCameraActive

    implicitWidth: Theme.compactPillSize

    PwObjectTracker {
        objects: root.allNodes
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
