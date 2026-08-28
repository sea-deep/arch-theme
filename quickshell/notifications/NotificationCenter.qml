import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    implicitWidth: 350
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    
    property bool isActive: false
    visible: isActive

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(26/255, 27/255, 38/255, 0.95)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Notifications"
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.fg
                    Layout.fillWidth: true
                }
                Switch {
                    id: dndSwitch
                    checked: NotificationServer.dndEnabled
                    onCheckedChanged: NotificationServer.dndEnabled = checked
                }
                Button {
                    text: "Clear All"
                    contentItem: Text {
                        text: parent.text
                        color: Theme.accent
                        font.family: Theme.fontFamilySans
                    }
                    background: Rectangle { color: "transparent" }
                    onClicked: NotificationServer.clearAll()
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: NotificationServer.notificationList
                spacing: 10
                clip: true
                
                delegate: NotificationCard {}
                
                Text {
                    visible: listView.count === 0
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: Theme.fgDim
                    font.family: Theme.fontFamilySans
                }
            }
        }
    }
}
