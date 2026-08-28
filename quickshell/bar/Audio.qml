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
            font.family: Theme.fontFamilySans
            font.pixelSize: Theme.fontSize
        }
    }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.exec("pavucontrol")
            } else if (mouse.button === Qt.MiddleButton) {
                Quickshell.exec("pactl set-sink-mute @DEFAULT_SINK@ toggle")
            }
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                Quickshell.exec("pactl set-sink-volume @DEFAULT_SINK@ +5%")
            } else {
                Quickshell.exec("pactl set-sink-volume @DEFAULT_SINK@ -5%")
            }
        }
    }
}
