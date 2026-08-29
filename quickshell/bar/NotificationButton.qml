import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../notifications"
import "../components" as Components

Components.Pill {
    id: root
    
    implicitWidth: Theme.compactPillSize

    readonly property string textVal: NotificationServer.dndEnabled
        ? "󱏧"
        : (NotificationServer.unreadCount > 0 ? "󱅫" : "󰂚")
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            text: root.textVal
            color: Theme.purple // CSS: #custom-swaync { color: #bb9af7; }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                UiState.toggleNotifications()
            } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                NotificationServer.toggleDnd()
            }
        }
    }
}
