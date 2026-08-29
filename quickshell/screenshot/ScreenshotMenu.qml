import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../components" as Components

PanelWindow {
    id: root
    WlrLayershell.namespace: "screenshot-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    property bool showing: UiState.screenshotVisible
    property real reveal: showing ? 1 : 0

    Behavior on reveal {
        NumberAnimation { duration: 150; easing.type: Easing.OutExpo }
    }
    
    // PanelWindow has no opacity, bind visible to showing
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
        onClicked: UiState.screenshotVisible = false
        // Dim the background
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, root.reveal * 0.5)
        }
    }

    Rectangle {
        id: menuItem
        opacity: root.reveal
        width: 320
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

        MouseArea {
            anchors.fill: parent
            // Eat clicks so it doesn't close
        }

        focus: true
        Keys.onPressed: (event) => {
            var handled = true;
            if (event.key === Qt.Key_Escape) {
                UiState.screenshotVisible = false;
            } else if (event.key === Qt.Key_F) {
                triggerScreenshot("full");
            } else if (event.key === Qt.Key_R) {
                triggerScreenshot("region");
            } else if (event.key === Qt.Key_W) {
                triggerScreenshot("window");
            } else {
                handled = false;
            }
            if (handled) event.accepted = true;
        }

        function triggerScreenshot(mode) {
            UiState.screenshotVisible = false;
            var script = Quickshell.env("HOME") + "/.config/hypr/screenshot.sh";
            Quickshell.execDetached(["bash", script, mode]);
        }

        ColumnLayout {
            id: layout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Screenshot"
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: 16
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 8
            }

            // Options
            Repeater {
                model: [
                    { key: "F", name: "Full Screen", mode: "full", icon: "video-display" },
                    { key: "R", name: "Selected Region", mode: "region", icon: "select-rectangular" },
                    { key: "W", name: "Specific Window", mode: "window", icon: "window-new" }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 6
                    color: hover.containsMouse ? Theme.bgLight : "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
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
                        
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 4
                            color: Theme.surface
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.key
                                color: Theme.accent
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menuItem.triggerScreenshot(modelData.mode)
                    }
                }
            }
        }
    }
}
