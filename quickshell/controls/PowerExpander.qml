import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Item {
    id: root

    property string targetScreenName: ""
    readonly property bool expanded: UiState.powerMenuVisible
        && (UiState.powerScreen === "" || UiState.powerScreen === targetScreenName)
    readonly property int bodyHeight: 228
    property real reveal: expanded ? 1 : 0

    implicitWidth: expanded || reveal > 0 ? 250 : Theme.compactPillSize
    implicitHeight: reveal > 0
        ? Theme.barHeight + Theme.outerGap + bodyHeight * reveal
        : Theme.barHeight
    focus: expanded

    Behavior on reveal {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate }
    }

    onExpandedChanged: {
        if (expanded)
            Qt.callLater(() => root.forceActiveFocus())
    }

    function runAction(action) {
        UiState.powerMenuVisible = false
        Quickshell.execDetached(action)
    }

    Keys.onEscapePressed: UiState.powerMenuVisible = false
    Keys.onPressed: event => {
        const shortcuts = {
            "L": ["loginctl", "lock-session"],
            "U": ["systemctl", "suspend"],
            "E": ["sh", "-c", "loginctl terminate-user $USER"],
            "R": ["systemctl", "reboot"],
            "S": ["systemctl", "poweroff"],
            "H": ["systemctl", "hibernate"]
        }
        const action = shortcuts[event.text.toUpperCase()]
        if (action) {
            root.runAction(action)
            event.accepted = true
        }
    }

    Components.ConnectedDropdownSurface {
        anchors.fill: parent
        hasLeftShoulder: true
        hasRightShoulder: false
        hasBottomRightInverted: true
        visible: root.reveal > 0
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        width: Theme.compactPillSize
        height: Theme.barHeight
        visible: root.reveal <= 0
        color: (powerHover.hovered && !UiState.hasActiveOverlay) ? Theme.bgLight : "transparent"
        topLeftRadius: Theme.radius
        bottomLeftRadius: Theme.radius
        topRightRadius: 0
        bottomRightRadius: 0

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        HoverHandler { id: powerHover }
    }

    Item {
        anchors.top: parent.top
        anchors.right: parent.right
        width: Theme.compactPillSize
        height: Theme.barHeight

        Text {
            anchors.centerIn: parent
            text: ""
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: UiState.togglePower(root.targetScreenName)
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bodyHeight * root.reveal
        visible: height > 0
        color: "transparent"
        border.width: 0
        clip: true

        Item {
            anchors.top: parent.top
            width: parent.width
            height: root.bodyHeight

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 7

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 25
                    text: "Session"
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 14
                    font.weight: Theme.fontWeight
                    verticalAlignment: Text.AlignVCenter
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: [
                            { name: "Lock", icon: "", action: ["loginctl", "lock-session"], key: "L" },
                            { name: "Suspend", icon: "󰤄", action: ["systemctl", "suspend"], key: "U" },
                            { name: "Logout", icon: "󰍃", action: ["sh", "-c", "loginctl terminate-user $USER"], key: "E" },
                            { name: "Reboot", icon: "󰑐", action: ["systemctl", "reboot"], key: "R" },
                            { name: "Shutdown", icon: "󰐥", action: ["systemctl", "poweroff"], key: "S" },
                            { name: "Hibernate", icon: "󰒲", action: ["systemctl", "hibernate"], key: "H" }
                        ]

                        Rectangle {
                            id: actionButton
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 0
                            radius: 9
                            color: btnMouseArea.containsMouse ? Theme.accent : Theme.bgLight
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 8
                                spacing: 7
                                Text {
                                    Layout.preferredWidth: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    text: actionButton.modelData.icon
                                    color: btnMouseArea.containsMouse ? Theme.bgDark : Theme.red
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: actionButton.modelData.name
                                    color: btnMouseArea.containsMouse ? Theme.bgDark : Theme.fg
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 11
                                    font.weight: Theme.fontWeight
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: actionButton.modelData.key
                                    color: btnMouseArea.containsMouse ? Theme.bgDark : Theme.fgMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                            MouseArea {
                                id: btnMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runAction(actionButton.modelData.action)
                            }
                        }
                    }
                }
            }
        }
    }
}
