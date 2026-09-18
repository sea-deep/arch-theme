import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    // Discover video capture streams in the PipeWire graph
    readonly property var videoStreams: {
        if (!Pipewire.nodes || !Pipewire.nodes.values) return []
        return Pipewire.nodes.values.filter(node => {
            if (!node || !node.isStream || node.isSink) return false
            if (node.properties) {
                const mediaClass = node.properties["media.class"] || ""
                const mediaRole = node.properties["media.role"] || ""
                if (mediaClass === "Stream/Input/Video") return true
                if (mediaRole === "Camera") return true
                if (mediaClass.indexOf("Video") !== -1) return true
            }
            return false
        })
    }

    // Discover active links to or from video sources (hardware webcams)
    readonly property var activeCameraLinks: {
        if (!Pipewire.linkGroups || !Pipewire.linkGroups.values) return []
        return Pipewire.linkGroups.values.filter(lg => {
            if (!lg || !lg.source || !lg.source.properties) return false
            const mediaClass = lg.source.properties["media.class"] || ""
            return mediaClass === "Video/Source"
        })
    }

    // Hardware camera nodes
    readonly property var cameraNodes: {
        if (!Pipewire.nodes || !Pipewire.nodes.values) return []
        return Pipewire.nodes.values.filter(node => {
            return node && !node.isStream && node.properties && node.properties["media.class"] === "Video/Source"
        })
    }

    readonly property bool isCameraActive: videoStreams.length > 0 || activeCameraLinks.length > 0

    // Only track camera nodes and active video streams (lightweight, zero churn crashes)
    PwObjectTracker {
        objects: root.cameraNodes.concat(root.videoStreams).filter(Boolean)
    }

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
