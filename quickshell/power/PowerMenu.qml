import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    color: Qt.rgba(26/255, 27/255, 38/255, 0.85)
    
    property bool isActive: false
    visible: isActive

    onIsActiveChanged: {
        if (isActive) {
            animEnter.start()
        }
    }

    ParallelAnimation {
        id: animEnter
        NumberAnimation { target: contentGrid; property: "scale"; from: 0.9; to: 1.0; duration: 300; easing.type: Easing.OutBack }
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 200 }
    }

    TapHandler {
        onTapped: root.isActive = false
    }

    Item {
        anchors.fill: parent
        focus: isActive
        Keys.onEscapePressed: root.isActive = false
        Keys.onPressed: (event) => {
            switch(event.key) {
                case Qt.Key_L: execProcess.command = ["hyprlock"]; break;
                case Qt.Key_U: execProcess.command = ["systemctl", "suspend"]; break;
                case Qt.Key_E: execProcess.command = ["hyprctl", "dispatch", "exit"]; break;
                case Qt.Key_R: execProcess.command = ["systemctl", "reboot"]; break;
                case Qt.Key_S: execProcess.command = ["systemctl", "poweroff"]; break;
                case Qt.Key_H: execProcess.command = ["systemctl", "hibernate"]; break;
                default: return;
            }
            execProcess.running = true;
            root.isActive = false;
        }
    }

    Process { id: execProcess }

    GridLayout {
        id: contentGrid
        anchors.centerIn: parent
        columns: 3
        rowSpacing: 30
        columnSpacing: 30

        Repeater {
            model: [
                { name: "Lock", icon: "", action: ["hyprlock"], key: "l" },
                { name: "Suspend", icon: "󰤄", action: ["systemctl", "suspend"], key: "u" },
                { name: "Logout", icon: "󰍃", action: ["hyprctl", "dispatch", "exit"], key: "e" },
                { name: "Reboot", icon: "󰑐", action: ["systemctl", "reboot"], key: "r" },
                { name: "Shutdown", icon: "󰐥", action: ["systemctl", "poweroff"], key: "s" },
                { name: "Hibernate", icon: "󰒲", action: ["systemctl", "hibernate"], key: "h" }
            ]
            
            delegate: Rectangle {
                width: 150
                height: 150
                radius: 20
                color: hover.hovered ? Theme.accent : Theme.bgLight
                border.color: hover.hovered ? Theme.accentGlow : "transparent"
                border.width: hover.hovered ? 2 : 0

                HoverHandler { id: hover }
                TapHandler {
                    onTapped: {
                        execProcess.command = modelData.action
                        execProcess.running = true
                        root.isActive = false
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        text: modelData.icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 48
                        color: hover.hovered ? Theme.bgDark : Theme.fg
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: modelData.name
                        font.family: Theme.fontFamilySans
                        font.bold: true
                        color: hover.hovered ? Theme.bgDark : Theme.fg
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
