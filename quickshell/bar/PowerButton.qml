import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            text: "󰐥"
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: {
            Quickshell.exec("quickshell ipc call power toggle")
        }
    }
}
