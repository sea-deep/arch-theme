import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    implicitWidth: 350
    implicitHeight: card.height + 40
    
    anchors.top: true
    anchors.right: true
    margins.top: 20
    margins.right: 20
    
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    
    property bool isActive: false
    visible: isActive
    
    Connections {
        target: NotificationServer
        function onNotificationReceived() {
            root.isActive = true
            slideIn.restart()
            autoDismiss.restart()
        }
    }
    
    Timer {
        id: autoDismiss
        interval: 5000
        onTriggered: root.isActive = false
    }

    Rectangle {
        id: card
        width: parent.width
        height: content.height + 20
        color: Theme.bgLight
        radius: Theme.radius
        border.color: hover.hovered ? Theme.accent : "transparent"
        border.width: 1

        NumberAnimation on opacity {
            id: slideIn
            from: 0
            to: 1
            duration: 200
        }

        HoverHandler { id: hover }
        TapHandler { onTapped: root.isActive = false }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8
            
            RowLayout {
                spacing: 8
                Image {
                    source: (NotificationServer.latestNotification && NotificationServer.latestNotification.appIcon) ? ("image://icon/" + NotificationServer.latestNotification.appIcon) : ""
                    sourceSize: Qt.size(24, 24)
                    Layout.alignment: Qt.AlignVCenter
                    visible: source !== ""
                }
                Text {
                    text: (NotificationServer.latestNotification && NotificationServer.latestNotification.summary) ? NotificationServer.latestNotification.summary : "Notification"
                    font.family: Theme.fontFamilySans
                    font.bold: true
                    color: Theme.fg
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            
            Text {
                text: (NotificationServer.latestNotification && NotificationServer.latestNotification.body) ? NotificationServer.latestNotification.body : ""
                font.family: Theme.fontFamilySans
                color: Theme.fgDim
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }
}
