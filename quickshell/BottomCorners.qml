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

    readonly property bool hasTiledWindows: Hyprland.activeToplevel !== null

    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    implicitHeight: 12
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    margins.bottom: 0
    margins.left: 0
    margins.right: 0

    mask: Region {
        Region { item: leftCorner }
        Region { item: rightCorner }
    }

    Components.InvertedCorner {
        id: leftCorner
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        cornerRadius: 12
        flipVertical: true
        opacity: root.hasTiledWindows ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }
    }

    Components.InvertedCorner {
        id: rightCorner
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        cornerRadius: 12
        flipHorizontal: true
        flipVertical: true
        opacity: root.hasTiledWindows ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }
    }
}
