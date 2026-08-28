import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../theme"

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    
    // Fallback safely if displayDevice is null
    property real percentage: UPower.displayDevice ? UPower.displayDevice.percentage : 100
    property int state: UPower.displayDevice ? UPower.displayDevice.state : UPower.DeviceState.Unknown
    property string iconName: UPower.displayDevice ? UPower.displayDevice.iconName : ""
    
    property bool isCritical: state === UPower.DeviceState.Discharging && percentage < 20
    
    // Map standard UPower icons to nerd font icons if we want text icons,
    // or we can use the native iconName with an Image.
    // The user wants the Sway style which uses Nerd Font text icons.
    function getBatteryIcon() {
        if (state === UPower.DeviceState.Charging || state === UPower.DeviceState.PendingCharge) {
            return "󰂄"
        }
        if (percentage >= 95) return "󰁹"
        if (percentage >= 90) return "󰂂"
        if (percentage >= 80) return "󰂁"
        if (percentage >= 70) return "󰂀"
        if (percentage >= 60) return "󰁿"
        if (percentage >= 50) return "󰁾"
        if (percentage >= 40) return "󰁽"
        if (percentage >= 30) return "󰁼"
        if (percentage >= 20) return "󰁻"
        if (percentage >= 10) return "󰁺"
        return "󰂃" // empty/critical
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Theme.spacing
        
        Text {
            text: root.getBatteryIcon()
            color: root.isCritical ? (blinkTimer.blinkState ? Theme.red : Theme.bg) : Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            
            Timer {
                id: blinkTimer
                interval: 500
                running: root.isCritical
                repeat: true
                property bool blinkState: false
                onTriggered: blinkState = !blinkState
            }
        }
        
        Text {
            text: Math.round(root.percentage) + "%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }
}
