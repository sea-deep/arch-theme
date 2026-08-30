import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    // Detect active video capture stream natively in the PipeWire graph
    readonly property var videoStreams: {
        if (!Pipewire.nodes || !Pipewire.nodes.values) return []
        return Pipewire.nodes.values.filter(node => node && node.isStream && node.audio === null)
    }
    readonly property bool isCameraActive: videoStreams.length > 0

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
