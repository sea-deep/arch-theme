import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property color strokeColor: Theme.surfaceVariant
    readonly property real inset: 1
    readonly property real corner: Theme.radiusLarge

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: 1.5
        strokeColor: root.strokeColor
        fillColor: Theme.bg
        joinStyle: ShapePath.RoundJoin

        // Start bottom-left
        startX: root.inset
        startY: root.height - root.inset

        // Go to top-left corner
        PathLine { x: root.inset; y: root.corner }
        PathQuad {
            controlX: root.inset; controlY: root.inset
            x: root.corner; y: root.inset
        }

        // Go to top-right corner
        PathLine { x: root.width - root.corner; y: root.inset }
        PathQuad {
            controlX: root.width - root.inset; controlY: root.inset
            x: root.width - root.inset; y: root.corner
        }

        // Go to bottom-right
        PathLine { x: root.width - root.inset; y: root.height - root.inset }

        // Go back to bottom-left (flat bottom edge)
        PathLine { x: root.inset; y: root.height - root.inset }
    }
}
