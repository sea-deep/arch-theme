import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    
    property bool isMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false
    property int volume: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0
    
    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Theme.spacing
        
        Text {
            text: root.isMuted ? "󰖁" : (root.volume > 50 ? "󰕾" : (root.volume > 0 ? "󰖀" : "󰕿"))
            color: root.isMuted ? Theme.red : Theme.blue
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
        }
        
        Text {
            text: root.volume + "%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                if (Pipewire.defaultAudioSink) {
                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                }
            }
        }
        onWheel: (wheel) => {
            if (Pipewire.defaultAudioSink) {
                if (wheel.angleDelta.y > 0) {
                    Pipewire.defaultAudioSink.audio.volume = Math.min(1.5, Pipewire.defaultAudioSink.audio.volume + 0.05)
                } else {
                    Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Pipewire.defaultAudioSink.audio.volume - 0.05)
                }
            }
        }
    }
}
