import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme" as Theme
import "../components" as Components

Components.Pill {
    id: root
    
    property bool isCapsOn: false
    
    collapseWhenEmpty: true
    isEmpty: !isCapsOn
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    Process {
        id: capsProc
        command: ["sh", "-c", "~/.config/quickshell/scripts/capslock.sh"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.isCapsOn = data.trim() === "on"
            }
        }
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: capsProc.running = true
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            text: "󰪛"
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            visible: root.isCapsOn
        }
    }
}
