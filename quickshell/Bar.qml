import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "theme"
import "bar" as BarModules
import "controls" as Controls

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    required property var modelData
    screen: modelData
    readonly property bool overlayExpanded: hardwarePill.expanded || trayExpander.expanded || networkExpander.expanded || notificationExpander.expanded || powerExpander.expanded || clockExpander.expanded || clipboardExpander.expanded

    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Keep the layer surface stable. Resizing the surface with the hardware
    // pill made every bar module jump during the close animation and left the
    // revealed controls outside the compositor's input region.
    implicitHeight: Math.max(Theme.barHeight,
        root.screen ? root.screen.height - Theme.outerGap : Theme.barHeight)
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: Theme.barHeight
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    margins.top: Theme.outerGap
    margins.left: Theme.outerGap
    margins.right: Theme.outerGap

    mask: Region {
        Region {
            x: 0
            y: 0
            width: root.width
            height: Theme.barHeight
        }
        // Retain each pill's animated geometry while it closes.
        Region { item: hardwarePill }
        Region { item: trayExpander }
        Region { item: networkExpander }
        Region { item: notificationExpander }
        Region { item: powerExpander }
        Region { item: clockExpander }
        Region { item: clipboardExpander }
        Region { item: workspacesModule }
    }

    Item {
        id: barContent
        Keys.onEscapePressed: UiState.closeOverlays()
        anchors.fill: parent

        MouseArea {
            id: bgMouseArea
            anchors.fill: parent
            enabled: root.overlayExpanded
            z: 0
            onClicked: {
                UiState.quickControlVisible = false
                UiState.notificationCenterVisible = false
                UiState.notificationPreviewVisible = false
                UiState.powerMenuVisible = false
                UiState.trayMenuVisible = false
                UiState.clockMenuVisible = false
                UiState.networkVisible = false
                UiState.clipboardVisible = false
            }
        }

        // LEFT (Workspaces)
        RowLayout {
            z: 1
            anchors.left: parent.left
            anchors.top: parent.top
            height: Theme.barHeight
            spacing: Theme.moduleSpacing

            BarModules.Workspaces {
                id: workspacesModule
            }
        }

        // CENTER (Clock + calendar expander)
        Item {
            id: clockSlot
            z: 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            height: Theme.barHeight
            width: clockExpander.topWidth
        }

        // RIGHT
        RowLayout {
            id: rightModules
            z: 1
            anchors.right: parent.right
            anchors.top: parent.top
            width: implicitWidth
            height: Theme.barHeight
            spacing: Theme.moduleSpacing

            BarModules.Recorder {}
            BarModules.CapsLock {}
            BarModules.AutoSleep { hostWindow: root }
            Item {
                id: clipboardSlot
                Layout.preferredWidth: Theme.compactPillSize
                Layout.preferredHeight: Theme.barHeight
                BarModules.Clipboard { anchors.centerIn: parent }
            }
            Item {
                id: notificationSlot
                Layout.preferredWidth: Theme.compactPillSize
                Layout.preferredHeight: Theme.barHeight
            }
            Item {
                id: traySlot
                Layout.preferredWidth: trayExpander.isEmpty ? 0 : trayExpander.collapsedWidth
                Layout.preferredHeight: Theme.barHeight
            }
            Item {
                id: networkSlot
                Layout.preferredWidth: Theme.compactPillSize
                Layout.preferredHeight: Theme.barHeight
            }
            
            Item {
                id: hardwareSlot
                Layout.preferredWidth: hardwarePill.implicitWidth
                Layout.preferredHeight: Theme.barHeight
            }
            
            Item {
                id: powerSlot
                Layout.preferredWidth: Theme.compactPillSize
                Layout.preferredHeight: Theme.barHeight
            }
        }

        // The expander must not be a child of the 34px RowLayout/slot. QtQuick
        // can paint children outside those ancestors, but it will not descend
        // into them for pointer hit-testing outside their bounds.
        Controls.QuickControls {
            id: hardwarePill
            z: 2
            x: rightModules.x + hardwareSlot.x
                + (hardwareSlot.width - width) / 2
            y: 0
            targetScreenName: root.screen.name
        }

        Controls.ClipboardExpander {
            id: clipboardExpander
            z: 4
            x: rightModules.x + clipboardSlot.x
            expandedWidth: rightModules.width - clipboardSlot.x
            y: 0
            targetScreenName: root.screen.name
        }

        Controls.NotificationExpander {
            id: notificationExpander
            z: 4
            x: rightModules.x + notificationSlot.x
            expandedWidth: rightModules.width - notificationSlot.x
            y: 0
            targetScreenName: root.screen.name
            maximumBodyHeight: root.height - Theme.barHeight - Theme.outerGap
        }

        Controls.PowerExpander {
            id: powerExpander
            z: 5
            x: rightModules.x + powerSlot.x + powerSlot.width - width
            y: 0
            targetScreenName: root.screen.name
        }

        Controls.TrayExpander {
            id: trayExpander
            z: 3
            x: rightModules.x + traySlot.x
            expandedWidth: rightModules.width - traySlot.x
            y: 0
            targetScreenName: root.screen.name
        }

        Controls.NetworkExpander {
            id: networkExpander
            z: 4
            x: rightModules.x + networkSlot.x
            expandedWidth: rightModules.width - networkSlot.x
            y: 0
            targetScreenName: root.screen.name
        }

        Controls.ClockExpander {
            id: clockExpander
            z: 6
            x: (barContent.width - width) / 2
            y: 0
            targetScreenName: root.screen.name
        }
    }

}
