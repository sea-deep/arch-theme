import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme" as Theme

RowLayout {
    id: root
    spacing: Theme.spacing
    
    property string icon: "󰁹"
    property string percentage: "100%"
    property bool isCritical: false
    property bool isDischarging: false
    
    Process {
        id: batProc
        command: ["sh", "-c", "~/.config/quickshell/scripts/battery.sh"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data)
                    root.icon = obj.alt || "󰁹"
                    root.percentage = obj.text || "100%"
                    
                    // Basic class parsing
                    let cls = obj.class || ""
                    root.isDischarging = !cls.includes("charging") && !cls.includes("plugged")
                    
                    let pctVal = parseInt(root.percentage.replace("%", ""))
                    root.isCritical = root.isDischarging && pctVal < 20
                } catch (e) {
                    console.log("Failed to parse battery JSON: ", e)
                }
            }
        }
    }
    
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batProc.running = true
    }
    
    Text {
        text: root.icon
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
        text: root.percentage
        color: Theme.fg
        font.family: Theme.fontFamilySans
        font.pixelSize: Theme.fontSize
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.exec("sh ~/.config/quickshell/scripts/tlp_menu.sh")
    }
}
