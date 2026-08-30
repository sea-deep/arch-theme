import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "theme"
import "components" as Components
import "bar" as BarModules
import "controls" as Controls

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    required property var modelData
    screen: modelData
    readonly property bool overlayExpanded: hardwarePill.expanded || trayExpander.expanded || networkExpander.expanded || notificationExpander.expanded || powerExpander.expanded || clockExpander.expanded
    readonly property bool hasTiledWindows: {
        const ws = Hyprland.focusedWorkspace
        if (!ws || !ws.toplevels || !ws.toplevels.values)
            return false
        return ws.toplevels.values.length > 0
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Keep the layer surface stable. Resizing the surface with the hardware
    // pill made every bar module jump during the close animation and left the
    // revealed controls outside the compositor's input region.
    implicitHeight: Math.max(Theme.barHeight,
        root.screen ? root.screen.height : Theme.barHeight)
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: Theme.barHeight
    WlrLayershell.keyboardFocus: root.overlayExpanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    margins.top: 0
    margins.left: 0
    margins.right: 0

    onOverlayExpandedChanged: {
        if (overlayExpanded) {
            Qt.callLater(() => barContent.forceActiveFocus())
        }
    }

    mask: Region {
        Region {
            x: 0
            y: 0
            width: root.width
            height: root.overlayExpanded ? root.height : Theme.barHeight
        }
        Region { item: leftCornerCurve }
        Region { item: rightCornerCurve }
        // Retain each pill's animated geometry while it closes.
        Region { item: hardwarePill }
        Region { item: trayExpander }
        Region { item: networkExpander }
        Region { item: notificationExpander }
        Region { item: powerExpander }
        Region { item: clockExpander }
        Region { item: workspacesModule }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.overlayExpanded
        onActivated: UiState.closeOverlays()
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            if (root.overlayExpanded) {
                UiState.closeOverlays()
            }
        }
        function onFocusedWorkspaceChanged() {
            if (root.overlayExpanded) {
                UiState.closeOverlays()
            }
        }
    }

    Item {
        id: barContent
        Keys.onEscapePressed: UiState.closeOverlays()
        focus: root.overlayExpanded
        anchors.fill: parent

        // Continuous full-width fluid black status bar background
        Rectangle {
            id: solidBarBg
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.barHeight
            color: Theme.bg
            z: 0
        }

        // Top-Left concave corner fillet connecting status bar to left screen edge
        Components.InvertedCorner {
            id: leftCornerCurve
            z: 0
            anchors.top: solidBarBg.bottom
            anchors.left: parent.left
            cornerRadius: 10
            opacity: root.hasTiledWindows ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }
        }

        // Top-Right concave corner fillet connecting status bar to right screen edge
        Components.InvertedCorner {
            id: rightCornerCurve
            z: 0
            anchors.top: solidBarBg.bottom
            anchors.right: parent.right
            cornerRadius: 10
            flipHorizontal: true
            opacity: root.hasTiledWindows ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }
        }

        MouseArea {
            id: bgMouseArea
            anchors.fill: parent
            enabled: root.overlayExpanded
            z: 0
            onClicked: UiState.closeOverlays()
        }

        // LEFT (Workspaces Expander)
        BarModules.Workspaces {
            id: workspacesModule
            z: 3
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: parent.top
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
            anchors.rightMargin: 0
            anchors.top: parent.top
            width: implicitWidth
            height: Theme.barHeight
            spacing: Theme.moduleSpacing

            BarModules.Recorder {}
            BarModules.CapsLock {}
            BarModules.AutoSleep { hostWindow: root }
            Item {
                id: clipboardSlot
                visible: Theme.showClipboardOnBar
                Layout.preferredWidth: Theme.showClipboardOnBar ? Theme.compactPillSize : 0
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
