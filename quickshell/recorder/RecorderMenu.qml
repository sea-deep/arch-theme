import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../components" as Components

PanelWindow {
    id: root
    WlrLayershell.namespace: "recorder-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property bool showing: UiState.recorderMenuVisible
    property real reveal: showing ? 1 : 0

    Behavior on reveal {
        NumberAnimation { duration: 150; easing.type: Easing.OutExpo }
    }
    
    visible: reveal > 0

    onShowingChanged: {
        if (showing) {
            Qt.callLater(function() {
                menuItem.forceActiveFocus()
            })
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.recorderMenuVisible = false
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, root.reveal * 0.5)
        }
    }

    property string selectedQuality: "balanced"
    property string selectedFormat: "mp4"

    Rectangle {
        id: menuItem
        opacity: root.reveal
        width: 360
        implicitHeight: layout.implicitHeight + 24
        anchors.centerIn: parent
        color: Theme.bg
        radius: Theme.radius
        border.color: Theme.accentGlow
        border.width: Theme.borderWidth

        transform: Scale {
            origin.x: menuItem.width / 2
            origin.y: menuItem.height / 2
            xScale: 0.9 + (0.1 * root.reveal)
            yScale: xScale
        }

        MouseArea { anchors.fill: parent }

        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                UiState.recorderMenuVisible = false;
                event.accepted = true;
            }
        }

        function triggerRecord(mode) {
            UiState.recorderMenuVisible = false;
            var script = Quickshell.env("HOME") + "/.config/hypr/toggle_recorder.sh";
            Quickshell.execDetached(["bash", script, mode, root.selectedQuality, root.selectedFormat]);
        }

        ColumnLayout {
            id: layout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 16

            Text {
                text: "Screen Recording"
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: 16
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }

            // Quality Selection
            Text {
                text: "Quality"
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: 12
                opacity: 0.7
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: ["high", "balanced", "low"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 6
                        color: root.selectedQuality === modelData ? Theme.accent : Theme.surface
                        Text {
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            color: root.selectedQuality === modelData ? Theme.bg : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: root.selectedQuality === modelData ? Font.Bold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedQuality = modelData
                        }
                    }
                }
            }

            // Format Selection
            Text {
                text: "Format"
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: 12
                opacity: 0.7
                Layout.topMargin: 8
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: ["mp4", "mkv"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 6
                        color: root.selectedFormat === modelData ? Theme.accent : Theme.surface
                        Text {
                            anchors.centerIn: parent
                            text: modelData.toUpperCase()
                            color: root.selectedFormat === modelData ? Theme.bg : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: root.selectedFormat === modelData ? Font.Bold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedFormat = modelData
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.surface
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            // Capture Options
            Repeater {
                model: [
                    { key: "F", name: "Record Full Screen", mode: "full", icon: "video-display" },
                    { key: "R", name: "Record Region", mode: "region", icon: "select-rectangular" },
                    { key: "W", name: "Record Window", mode: "window", icon: "window-new" }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 8
                    color: hover.containsMouse ? Theme.bgLight : Theme.surface
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        IconImage {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: Quickshell.iconPath(modelData.icon)
                        }
                        
                        Text {
                            text: modelData.name
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 14
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menuItem.triggerRecord(modelData.mode)
                    }
                }
            }
        }
    }
}
