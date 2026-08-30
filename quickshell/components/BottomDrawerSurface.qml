import QtQuick
import "../theme"

Item {
    id: root

    property color fillColor: Theme.bg
    property real shoulderRadius: 14
    property real cornerRadius: Theme.radiusLarge

    // Main card rectangle (hardware-accelerated GPU quad)
    Rectangle {
        anchors.fill: parent
        color: root.fillColor
        topLeftRadius: root.cornerRadius
        topRightRadius: root.cornerRadius
        bottomLeftRadius: 0
        bottomRightRadius: 0
    }

    // Bottom-Left concave inverted fillet
    InvertedCorner {
        anchors.bottom: parent.bottom
        anchors.right: parent.left
        cornerRadius: root.shoulderRadius
        flipVertical: true
        fillColor: root.fillColor
    }

    // Bottom-Right concave inverted fillet
    InvertedCorner {
        anchors.bottom: parent.bottom
        anchors.left: parent.right
        cornerRadius: root.shoulderRadius
        flipHorizontal: true
        flipVertical: true
        fillColor: root.fillColor
    }
}
