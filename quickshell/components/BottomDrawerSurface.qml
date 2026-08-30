import QtQuick
import "../theme"

Rectangle {
    id: root

    property color fillColor: Theme.bg
    property real cornerRadius: Theme.radiusLarge
    property real shoulderRadius: 0

    color: root.fillColor
    topLeftRadius: root.cornerRadius
    topRightRadius: root.cornerRadius
    bottomLeftRadius: root.cornerRadius
    bottomRightRadius: root.cornerRadius
    border.width: 1
    border.color: Theme.surfaceVariant
}
