import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool hasSource: source !== null && source.audio !== null && source.ready
    readonly property bool isMuted: !hasSource || source.audio.muted

    // Detect any active microphone capture stream natively in the PipeWire graph
    readonly property var recordingStreams: {
        if (!Pipewire.nodes || !Pipewire.nodes.values) return []
        return Pipewire.nodes.values.filter(node => node && node.isStream && !node.isSink && node.audio !== null)
    }
    readonly property bool isRecording: recordingStreams.length > 0

    // Only show the privacy pill when an app is actually capturing audio
    collapseWhenEmpty: true
    isEmpty: !isRecording

    implicitWidth: Theme.compactPillSize

    PwObjectTracker {
        objects: root.source ? [root.source].concat(root.recordingStreams) : root.recordingStreams
    }

    Text {
        anchors.centerIn: parent
        text: root.isMuted ? "󰍭" : "󰍬"
        color: root.isMuted ? Theme.red : Theme.orange
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.hasSource)
                root.source.audio.muted = !root.source.audio.muted
        }
    }
}
