import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    
    FileView {
        id: currentBright
        path: "/sys/class/backlight/intel_backlight/brightness"
    }
    
    FileView {
        id: maxBright
        path: "/sys/class/backlight/intel_backlight/max_brightness"
    }
    
    property int maxB: parseInt(maxBright.__text) || 100
    property int currB: parseInt(currentBright.__text) || 0
    property int brightness: maxB > 0 ? Math.round((currB / maxB) * 100) : 0
    
    RowLayout {
        id: layout
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
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                Quickshell.exec("brightnessctl set +5%")
            } else {
                Quickshell.exec("brightnessctl set 5%-")
            }
        }
    }
}
