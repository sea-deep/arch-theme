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
    readonly property int toastCount: (Notifications.NotificationServer.activeToasts || []).length
    readonly property bool showing: UiState.notificationCenterVisible || (UiState.notificationPreviewVisible && toastCount > 0)
    readonly property int fullBodyHeight: 500
    readonly property int previewBodyHeight: toastCount > 0 ? Math.min(500, previewLayout.implicitHeight + 24) : 0
    property real bodyHeight: UiState.notificationCenterVisible ? fullBodyHeight : previewBodyHeight
    property real expandedWidth: 380
    property real maximumBodyHeight: 500
    property real reveal: showing ? 1 : 0

    implicitWidth: (showing || reveal > 0.05) && bodyHeight > 10 ? expandedWidth : Theme.compactPillSize
    implicitHeight: reveal > 0.05 && bodyHeight > 10
        ? Theme.barHeight + Theme.outerGap + bodyHeight * reveal
        : Theme.barHeight
    width: implicitWidth
    height: implicitHeight
    focus: showing

    Behavior on reveal {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate }
    }
    Behavior on bodyHeight {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate }
    }

    Connections {
        target: Notifications.NotificationServer
        function onNotificationReceived() {
            if (!UiState.notificationCenterVisible) {
                UiState.showNotificationPreview(targetScreenName)
            }
        }
    }

    Connections {
        target: Notifications.NotificationServer.notificationList
        function onValuesChanged() {
            if (UiState.notificationCenterVisible && Notifications.NotificationServer.notificationList.values.length === 0) {
                closeAutoTimer.restart()
            }
        }
    }

    Timer {
        id: closeAutoTimer
        interval: 180
        onTriggered: {
            if (UiState.notificationCenterVisible && Notifications.NotificationServer.notificationList.values.length === 0) {
                UiState.notificationCenterVisible = false
            }
        }
    }

    onShowingChanged: {
        if (expanded) {
            if (UiState.notificationCenterVisible)
                Notifications.NotificationServer.markRead()
            Qt.callLater(() => root.forceActiveFocus())
        }
    }

    Keys.onEscapePressed: {
        UiState.notificationCenterVisible = false
        UiState.notificationPreviewVisible = false
    }

    Components.ConnectedDropdownSurface {
        id: connectedSurface
        z: 1
        anchors.fill: parent
        hasLeftShoulder: true
        hasRightShoulder: false
        hasBottomRightInverted: true
        visible: root.reveal > 0.05 && root.bodyHeight > 10
    }

    Components.Pill {
        z: 2
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight
        visible: !connectedSurface.visible || root.reveal <= 0.05
        
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
        z: 3
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
        z: 2
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.reveal > 0
        opacity: Math.max(0.0, Math.min(1.0, (root.reveal - 0.15) / 0.85))
        clip: true

        ColumnLayout {
            visible: UiState.notificationCenterVisible
            anchors.fill: parent
            
            anchors.margins: 12
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
                    radius: Theme.radiusSmall
                    color: Notifications.NotificationServer.dndEnabled ? Theme.purple : Theme.bgLight

                    Text {
                        id: dndLabel
                        anchors.centerIn: parent
                        text: Notifications.NotificationServer.dndEnabled ? "󱏧 DND" : "󰂚 DND"
                        color: Notifications.NotificationServer.dndEnabled ? Theme.bgDark : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Theme.fontWeight
                    }

                    TapHandler { onTapped: Notifications.NotificationServer.toggleDnd() }
                }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 16
                    implicitHeight: 28
                    radius: Theme.radiusSmall
                    color: clearHover.hovered ? Theme.surface : Theme.bgLight

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Theme.accent
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 13
                    }

                    HoverHandler { id: clearHover }
                    TapHandler {
                        onTapped: {
                            Notifications.NotificationServer.clearAll()
                            UiState.notificationCenterVisible = false
                        }
                    }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: Notifications.NotificationServer.notificationList
                spacing: 8
                clip: true
                
                delegate: Notifications.NotificationCard {
                    width: listView.width
                    notification: modelData
                    onDismissed: {
                        if (listView.count <= 1) {
                            UiState.notificationCenterVisible = false
                        }
                    }
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

        // ── Stacked Toast Notifier Popups ──
        Item {
            visible: !UiState.notificationCenterVisible && UiState.notificationPreviewVisible
            anchors.fill: parent

            ColumnLayout {
                id: previewLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                Repeater {
                    model: Notifications.NotificationServer.activeToasts
                    delegate: Item {
                        id: toastDelegate
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: toastCard.implicitHeight
                        implicitWidth: previewLayout.width

                        Timer {
                            id: toastTimer
                            interval: toastDelegate.modelData && toastDelegate.modelData.expireTimeout > 0
                                ? Math.max(2000, toastDelegate.modelData.expireTimeout * 1000)
                                : 5000
                            running: !toastHover.hovered && !toastCard.isSwiping
                            onTriggered: {
                                exitAnim.start()
                            }
                        }

                        ParallelAnimation {
                            id: exitAnim
                            NumberAnimation { target: toastCard; property: "opacity"; to: 0; duration: 160; easing.type: Easing.InQuad }
                            NumberAnimation { target: toastCard; property: "scale"; to: 0.95; duration: 160; easing.type: Easing.InQuad }
                            onFinished: {
                                Notifications.NotificationServer.removeToast(toastDelegate.modelData)
                            }
                        }

                        Notifications.NotificationCard {
                            id: toastCard
                            width: toastDelegate.width
                            notification: toastDelegate.modelData
                            onDismissed: {
                                Notifications.NotificationServer.removeToast(toastDelegate.modelData)
                            }

                            opacity: 0
                            scale: 0.96

                            Component.onCompleted: {
                                enterAnim.start()
                            }

                            ParallelAnimation {
                                id: enterAnim
                                NumberAnimation { target: toastCard; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                                NumberAnimation { target: toastCard; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                            }
                        }

                        HoverHandler {
                            id: toastHover
                        }
                    }
                }
            }
        }
    }
}
