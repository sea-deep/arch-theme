import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components" as Components
import "../notifications" as Notifications

Components.Pill {
    id: root
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing
        
        Text {
            text: Notifications.NotificationServer.unreadCount > 0 ? "󱅫" : "󰂚"
            color: Theme.purple
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
        }
        
        Text {
            text: Notifications.NotificationServer.unreadCount.toString()
            color: Theme.fg
            font.family: Theme.fontFamilySans
            font.pixelSize: Theme.fontSize
            visible: Notifications.NotificationServer.unreadCount > 0
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: {
            Quickshell.exec("quickshell ipc call notifications toggle")
        }
    }
}
