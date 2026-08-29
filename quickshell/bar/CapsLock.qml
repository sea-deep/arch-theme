import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    property string textVal: ""
    property string tooltipVal: ""
    
    collapseWhenEmpty: true
    isEmpty: textVal === ""
    
    implicitWidth: Theme.compactPillSize
    
    Process {
        id: capslockProc
        command: [Quickshell.shellPath("scripts/capslock.sh")]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let json = JSON.parse(data)
                    root.textVal = json.text
                    root.tooltipVal = json.tooltip
                } catch(e) {}
            }
        }
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            // text contains "<span color='#f7768e'> 󰪛 </span>" in waybar, we just render the icon directly based on logic,
            // or if we must parse the span... wait.
            // In QML, Text.textFormat: Text.RichText supports some html. But let's just use the icon.
            // The JSON from capslock.sh gives text: "<span color='#f7768e'> 󰪛 </span>" or "".
            text: root.textVal !== "" ? "󰪛" : ""
            color: Theme.red // f7768e
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            visible: text !== ""
        }
    }
}
