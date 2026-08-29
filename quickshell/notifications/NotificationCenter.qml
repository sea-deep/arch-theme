import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    implicitWidth: 320
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    margins.top: Theme.outerGap
    margins.right: Theme.outerGap
    margins.bottom: Theme.outerGap
    
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    
    visible: UiState.notificationCenterVisible

    Shortcut {
        sequence: "Escape"
        onActivated: UiState.notificationCenterVisible = false
    }

    onVisibleChanged: {
        if (visible) {
            NotificationServer.markRead()
            Qt.callLater(() => notificationFocus.forceActiveFocus())
        }
    }

    Item {
        id: notificationFocus
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: UiState.notificationCenterVisible = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.radius
        border.width: Theme.borderWidth
        border.color: Theme.bgDark

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "󰂚"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    color: Theme.purple
                    Layout.alignment: Qt.AlignVCenter
                }

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
                    color: NotificationServer.dndEnabled ? Theme.purple : Theme.bgLight

                    Text {
                        id: dndLabel
                        anchors.centerIn: parent
                        text: NotificationServer.dndEnabled ? "󱏧 DND" : "󰂚 DND"
                        color: NotificationServer.dndEnabled ? Theme.bgDark : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Theme.fontWeight
                    }

                    TapHandler { onTapped: NotificationServer.toggleDnd() }
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
                    TapHandler { onTapped: NotificationServer.clearAll() }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 9
                    color: closeHover.hovered ? Theme.surface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 18
                    }

                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: UiState.notificationCenterVisible = false }
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
                    text: "󰂛\n\nAll clear"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }
        }
    }
}
