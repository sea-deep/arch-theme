import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "theme"
import "components" as Components

PanelWindow {
    id: root
    WlrLayershell.namespace: "quickshell"
    required property var modelData
    screen: modelData

    readonly property bool hasTiledWindows: {
        const ws = Hyprland.focusedWorkspace
        if (!ws || !ws.toplevels || !ws.toplevels.values)
            return false
        return ws.toplevels.values.length > 0
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    margins.top: 0
    margins.bottom: 0
    margins.left: 0
    margins.right: 0

    mask: Region {
        Region { item: leftBar }
        Region { item: rightBar }
        Region { item: bottomBar }
        Region { item: topLeftCorner }
        Region { item: topRightCorner }
        Region { item: leftCorner }
        Region { item: rightCorner }
    }

    // Thin left vertical bar connecting top-left corner to bottom-left corner
    Rectangle {
        id: leftBar
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 2
        color: Theme.bg
    }

    // Thin right vertical bar connecting top-right corner to bottom-right corner
    Rectangle {
        id: rightBar
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 2
        color: Theme.bg
    }

    // Thin bottom horizontal bar connecting bottom-left corner to bottom-right corner
    Rectangle {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: Theme.bg
    }

    Components.InvertedCorner {
        id: topLeftCorner
        anchors.top: parent.top
        anchors.left: parent.left
        cornerRadius: 10
    }

    Components.InvertedCorner {
        id: topRightCorner
        anchors.top: parent.top
        anchors.right: parent.right
        cornerRadius: 10
        flipHorizontal: true
    }

    Components.InvertedCorner {
        id: leftCorner
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        cornerRadius: 10
        flipVertical: true
    }

    Components.InvertedCorner {
        id: rightCorner
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        cornerRadius: 10
        flipHorizontal: true
        flipVertical: true
    }
}
