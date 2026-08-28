import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Quickshell 1.0
import "../theme"

PanelWindow {
    id: root
    width: 350
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    
    color: Qt.rgba(26/255, 27/255, 38/255, 0.95)
    
    property bool isActive: false
    visible: isActive
    
    NumberAnimation on x {
        id: slideAnim
        from: isActive ? Screen.width : Screen.width - width
        to: isActive ? Screen.width - width : Screen.width
        duration: 300
        easing.type: Easing.OutCubic
        running: true
    }

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
