import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"

Item {
    id: root
    signal primaryClicked()
    implicitWidth: layout.implicitWidth + 16 // Matches Waybar's #pulseaudio { padding: 0 8px; }
    implicitHeight: Theme.barHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.audio !== null && sink.ready
    readonly property int volume: available ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool isMuted: !available || sink.audio.muted

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - 12)
        height: 2
        radius: 1
        color: Theme.blue
        opacity: audioHover.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingDecelerate } }
    }

    PwObjectTracker {
        objects: [root.sink]
    }
    
    function getIcon() {
        if (isMuted) return "󰖁"
        if (volume === 0) return "󰖁"
        if (volume < 33) return "󰕿"
        if (volume < 66) return "󰖀"
        return "󰕾"
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            text: root.getIcon()
            color: root.isMuted ? Theme.red : Theme.blue
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        
        Text {
            text: root.isMuted ? "Muted" : (root.volume + "%")
            color: root.isMuted ? Theme.red : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.primaryClicked()
            } else if (mouse.button === Qt.MiddleButton) {
                if (root.available)
                    root.sink.audio.muted = !root.sink.audio.muted
            }
        }
        onWheel: (wheel) => {
            if (!root.available)
                return

            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + delta))
        }
    }

    HoverHandler { id: audioHover }
}
