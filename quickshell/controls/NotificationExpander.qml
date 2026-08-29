import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components" as Components
import "../notifications" as Notifications

Item {
    id: root

    property string targetScreenName: ""
    readonly property bool expanded: UiState.notificationCenterVisible
    readonly property bool showing: UiState.notificationCenterVisible || UiState.notificationPreviewVisible
    readonly property int fullBodyHeight: 500
    readonly property int previewBodyHeight: previewLoader.item ? previewLoader.item.implicitHeight : 100
    readonly property int bodyHeight: UiState.notificationCenterVisible ? fullBodyHeight : previewBodyHeight
    property real expandedWidth: 380
    property real maximumBodyHeight: 500
    property real reveal: showing ? 1 : 0

    implicitWidth: showing || reveal > 0 ? expandedWidth : Theme.compactPillSize
    implicitHeight: reveal > 0
        ? Theme.barHeight + Theme.outerGap + bodyHeight * reveal
        : Theme.barHeight
    focus: showing

    Behavior on reveal {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate }
    }

    Timer {
        id: previewTimer
        interval: Notifications.NotificationServer.latestNotification && Notifications.NotificationServer.latestNotification.expireTimeout > 0
            ? Math.max(1500, Notifications.NotificationServer.latestNotification.expireTimeout * 1000)
            : 5000
        onTriggered: UiState.notificationPreviewVisible = false
    }

    Connections {
        target: Notifications.NotificationServer
        function onNotificationReceived() {
            if (!UiState.notificationCenterVisible) {
                UiState.showNotificationPreview(targetScreenName)
                previewTimer.restart()
            }
        }
    }

    onShowingChanged: {
        if (expanded) {
            if (UiState.notificationCenterVisible)
                Notifications.NotificationServer.markRead()
            Qt.callLater(() => root.forceActiveFocus())
        } else {
            previewTimer.stop()
        }
    }

    Keys.onEscapePressed: {
        UiState.notificationCenterVisible = false
        UiState.notificationPreviewVisible = false
    }

    Components.ConnectedDropdownSurface {
        anchors.fill: parent
        tabWidth: Theme.compactPillSize
        tabOnLeft: true
        visible: root.reveal > 0
    }

    Components.Pill {
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight
        visible: root.reveal <= 0
        
        Text {
            anchors.centerIn: parent
            text: Notifications.NotificationServer.dndEnabled
                ? "󱏧"
                : (Notifications.NotificationServer.unreadCount > 0 ? "󱅫" : "󰂚")
            color: Theme.purple
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight

        Text {
            anchors.centerIn: parent
            visible: root.reveal > 0
            text: Notifications.NotificationServer.dndEnabled
                ? "󱏧"
                : (Notifications.NotificationServer.unreadCount > 0 ? "󱅫" : "󰂚")
            color: Theme.purple
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    UiState.toggleNotifications()
                } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                    Notifications.NotificationServer.toggleDnd()
                }
            }
        }
    }

    Item {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.reveal > 0
        opacity: root.reveal
        clip: true

        ColumnLayout {
            visible: UiState.notificationCenterVisible
            anchors.fill: parent
            
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Notifications"
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 16
                    font.weight: Theme.fontWeight
                    color: Theme.fg
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    implicitWidth: dndLabel.implicitWidth + 16
                    implicitHeight: 28
                    radius: 9
                    color: Notifications.NotificationServer.dndEnabled ? Theme.purple : Theme.bgLight

                    Text {
                        id: dndLabel
                        anchors.centerIn: parent
                        text: Notifications.NotificationServer.dndEnabled ? "󱏧 DND" : "󰂚 DND"
                        color: Notifications.NotificationServer.dndEnabled ? Theme.bgDark : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Theme.fontWeight
                    }

                    TapHandler { onTapped: Notifications.NotificationServer.toggleDnd() }
                }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 16
                    implicitHeight: 28
                    radius: 9
                    color: clearHover.hovered ? Theme.surface : Theme.bgLight

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Theme.accent
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 11
                    }

                    HoverHandler { id: clearHover }
                    TapHandler { onTapped: Notifications.NotificationServer.clearAll() }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: Notifications.NotificationServer.notificationList
                spacing: 10
                clip: true
                
                delegate: Notifications.NotificationCard {
                    notification: modelData
                }
                
                Text {
                    visible: listView.count === 0
                    anchors.centerIn: parent
                    text: "󰂛\n\nAll clear"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }
        }

        Item {
            visible: !UiState.notificationCenterVisible && UiState.notificationPreviewVisible
            anchors.fill: parent
            

            Loader {
                id: previewLoader
                width: parent.width
                active: Notifications.NotificationServer.latestNotification !== null
                
                sourceComponent: Notifications.NotificationCard {
                    width: previewLoader.width
                    notification: Notifications.NotificationServer.latestNotification
                    implicitHeight: height
                    color: "transparent"
                    border.width: 0
                }
            }
            
            // Allow clicking the preview to close it or interact with it
            TapHandler {
                onTapped: UiState.notificationPreviewVisible = false
            }
        }
    }
}
