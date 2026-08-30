import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property color fillColor: Theme.bg
    property real cornerRadius: 14
    property bool flipHorizontal: false
    property bool flipVertical: false

    implicitWidth: cornerRadius
    implicitHeight: cornerRadius
    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.flipHorizontal ? -1 : 1
        yScale: root.flipVertical ? -1 : 1
    }

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillColor
        joinStyle: ShapePath.RoundJoin

        // Top-left corner (0, 0)
        startX: 0
        startY: 0

        // Line along the top horizontal edge (meets bar bottom)
        PathLine { x: root.width; y: 0 }

        // Concave arc curving towards bottom-left (meets vertical screen edge)
        PathQuad {
            controlX: 0
            controlY: 0
            x: 0
            y: root.height
        }

        // Line along the vertical edge back to start
        PathLine { x: 0; y: 0 }
    }
}
