import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "theme" as Theme
import "bar" as BarModules
import "components" as Components

PanelWindow {
    id: root

    required property var screen

    windowScreen: screen
    anchors.top: true
    anchors.left: true
    anchors.right: true

    height: Theme.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: Theme.barHeight
    margins.top: 3
    margins.left: 3
    margins.right: 3

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacing

        // LEFT
        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Theme.spacing
            
            BarModules.Workspaces {}
            BarModules.WindowTitle {}
        }

        // CENTER
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing
            
            BarModules.Clock {}
        }

        // RIGHT
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Theme.spacing
            
            BarModules.Recorder {}
            BarModules.Clipboard {}
            BarModules.CapsLock {}
            BarModules.AutoSleep {}
            BarModules.Tray {}
            BarModules.NotificationButton {}
            
            // Hardware Group
            Components.Pill {
                implicitWidth: hwLayout.implicitWidth + Theme.pillPadding * 2
                
                RowLayout {
                    id: hwLayout
                    anchors.centerIn: parent
                    spacing: Theme.spacing * 2
                    
                    BarModules.Audio {}
                    BarModules.Backlight {}
                    BarModules.Battery {}
                }
            }
            
            BarModules.PowerButton {}
        }
    }
}
