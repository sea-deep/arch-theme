import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
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
    readonly property var notification: NotificationServer.latestNotification
    visible: isActive && notification !== null
    
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
        interval: root.notification && root.notification.expireTimeout > 0
            ? Math.max(1500, root.notification.expireTimeout * 1000)
            : 5000
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
                IconImage {
                    implicitWidth: 24
                    implicitHeight: 24
                    source: root.notification
                        ? (root.notification.image !== ""
                            ? root.notification.image
                            : Quickshell.iconPath(root.notification.appIcon, "dialog-information"))
                        : ""
                    Layout.alignment: Qt.AlignVCenter
                    visible: source !== ""
                }
                Text {
                    text: root.notification && root.notification.summary !== "" ? root.notification.summary : "Notification"
                    font.family: Theme.fontFamilySans
                    font.weight: Theme.fontWeight
                    color: Theme.fg
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            
            Text {
                text: root.notification ? root.notification.body : ""
                textFormat: Text.StyledText
                font.family: Theme.fontFamilySans
                color: Theme.fgDim
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }
}
