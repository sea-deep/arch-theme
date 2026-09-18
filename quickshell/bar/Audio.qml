import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"

Item {
    id: root
    signal primaryClicked()
    implicitWidth: layout.implicitWidth + 16
    implicitHeight: Theme.barHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.audio !== null && sink.ready
    readonly property int volume: available ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool isMuted: !available || sink.audio.muted

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.radiusSmall
        color: audioHover.hovered ? Theme.bgLight : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    PwObjectTracker {
        objects: [root.sink].filter(Boolean)
    }
    
    function getIcon() {
        if (isMuted) return "󰖁"
        if (volume === 0) return "󰖁"
        if (volume < 33) return "󰕿"
        if (volume < 66) return "󰖀"
        return "󰕾"
    }
    
    FontMetrics {
        id: fm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 5
        
        Text {
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
            text: root.getIcon()
            color: root.isMuted ? Theme.red : Theme.blue
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        
        Text {
            Layout.preferredWidth: Math.max(Math.ceil(fm.advanceWidth("100%")), root.isMuted ? Math.ceil(fm.advanceWidth("Muted")) : 0)
            horizontalAlignment: Text.AlignLeft
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
