import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property color fillColor: Theme.bg
    property real cornerRadius: 10
    property bool flipHorizontal: false
    property bool flipVertical: false

    implicitWidth: cornerRadius
    implicitHeight: cornerRadius
    preferredRendererType: Shape.GeometryRenderer

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.flipHorizontal ? -1 : 1
        yScale: root.flipVertical ? -1 : 1
    }

    ShapePath {
        strokeWidth: 1.5
        strokeColor: root.fillColor
        fillColor: root.fillColor
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap

        // Start at corner (0, 0)
        startX: 0
        startY: 0

        // Line along the horizontal edge
        PathLine { x: root.width; y: 0 }

        // Exact circular arc matching window outer rounding
        PathArc {
            x: 0
            y: root.height
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            direction: PathArc.Counterclockwise
        }

        // Line along the vertical edge back to (0, 0)
        PathLine { x: 0; y: 0 }
    }
}
