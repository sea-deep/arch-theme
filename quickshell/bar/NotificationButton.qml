import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme" as Theme
import "../components" as Components

Components.Pill {
    id: root
    
    // In a real implementation this would tie into the notification daemon state
    property int notificationCount: 0
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing
        
        Text {
            text: root.notificationCount > 0 ? "󱅫" : "󰂚"
            color: Theme.purple
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
        }
        
        Text {
            text: root.notificationCount.toString()
            color: Theme.fg
            font.family: Theme.fontFamilySans
            font.pixelSize: Theme.fontSize
            visible: root.notificationCount > 0
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: {
            // Toggle notification center
        }
    }
}
