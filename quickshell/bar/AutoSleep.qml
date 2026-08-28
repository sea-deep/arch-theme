import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    property bool isDisabled: false
    
    collapseWhenEmpty: true
    isEmpty: !isDisabled
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    Process {
        id: sleepProc
        command: ["sh", "-c", "test -f ~/.config/hypr/.autosleep_disabled && echo 'disabled' || echo 'enabled'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.isDisabled = data.trim() === "disabled"
            }
        }
    }
    
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sleepProc.running = true
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            text: "󰅶"
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            visible: root.isDisabled
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: Quickshell.exec("sh ~/.config/quickshell/scripts/toggle_idle.sh")
    }
}
