import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    property bool isV4l2Active: false

    // Hardware camera device nodes from PipeWire
    readonly property var cameraNodes: {
        if (!Pipewire.nodes || !Pipewire.nodes.values) return []
        return Pipewire.nodes.values.filter(node => {
            return node && !node.isStream && node.properties && node.properties["media.class"] === "Video/Source"
        })
    }

    // Video device paths dynamically discovered from PipeWire camera nodes
    readonly property var cameraPaths: {
        const paths = []
        for (const node of root.cameraNodes) {
            const path = node.properties ? node.properties["api.v4l2.path"] : ""
            if (path && paths.indexOf(path) === -1) paths.push(path)
        }
        return paths.length > 0 ? paths : ["/dev/video0", "/dev/video2"]
    }

    // Direct V4L2 device check for apps that bypass PipeWire (e.g. Discord, Electron, Cheese, ffmpeg)
    Process {
        id: v4l2CheckProc
        command: ["fuser", "-s"].concat(root.cameraPaths)
        onExited: (exitCode) => {
            root.isV4l2Active = (exitCode === 0)
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.isPipewireActive && !v4l2CheckProc.running) {
                v4l2CheckProc.command = ["fuser", "-s"].concat(root.cameraPaths)
                v4l2CheckProc.running = true
            }
        }
    }

    // Discover video capture streams in the PipeWire graph (e.g. Firefox, Zen, OBS PipeWire, Portal)
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

    readonly property bool isPipewireActive: videoStreams.length > 0 || activeCameraLinks.length > 0
    readonly property bool isCameraActive: isPipewireActive || isV4l2Active

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
