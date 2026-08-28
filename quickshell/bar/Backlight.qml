import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    
    property int brightness: 0
    
    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let val = parseInt(data)
                if (!isNaN(val)) root.brightness = val
            }
        }
    }
    
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: brightnessProc.running = true
    }
    
    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Theme.spacing
        
        Text {
            text: root.brightness > 50 ? "󰃠" : (root.brightness > 20 ? "󰃟" : "󰃞")
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
        }
        
        Text {
            text: root.brightness + "%"
            color: Theme.fg
            font.family: Theme.fontFamilySans
            font.pixelSize: Theme.fontSize
        }
    }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                Quickshell.exec("sh ~/.config/quickshell/scripts/toggle_idle.sh")
            }
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                Quickshell.exec("brightnessctl set +1%")
                brightnessProc.running = true
            } else {
                Quickshell.exec("brightnessctl set 1%-")
                brightnessProc.running = true
            }
        }
    }
}
