import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property color fillColor: Theme.bgLight
    property real shoulderRadius: 14
    property real cornerRadius: Theme.radius
    property real leftShoulder: shoulderRadius
    property real rightShoulder: shoulderRadius
    property real bodyTop: Theme.barHeight
    property real tabWidth: Theme.compactPillSize
    property bool tabOnLeft: false
    readonly property real bodyHeight: Math.max(0, height - bodyTop)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillColor
        joinStyle: ShapePath.RoundJoin

        // Start at left shoulder where bar bottom meets inverted fillet
        startX: -root.leftShoulder
        startY: root.bodyTop

        // Inverted fillet on top-left: curves concavely from (-S, bodyTop) into (0, bodyTop + S)
        PathQuad {
            controlX: 0
            controlY: root.bodyTop
            x: 0
            y: root.bodyTop + root.leftShoulder
        }

        // Left edge going down to bottom-left corner
        PathLine {
            x: 0
            y: Math.max(root.bodyTop + root.leftShoulder, root.height - root.cornerRadius)
        }

        // Bottom-left rounded corner
        PathQuad {
            controlX: 0
            controlY: root.height
            x: Math.min(root.cornerRadius, root.width / 2)
            y: root.height
        }

        // Bottom edge going right
        PathLine {
            x: Math.max(root.cornerRadius, root.width - root.cornerRadius)
            y: root.height
        }

        // Bottom-right rounded corner
        PathQuad {
            controlX: root.width
            controlY: root.height
            x: root.width
            y: Math.max(root.bodyTop + root.rightShoulder, root.height - root.cornerRadius)
        }

        // Right edge going up to right shoulder
        PathLine {
            x: root.width
            y: root.bodyTop + root.rightShoulder
        }

        // Inverted fillet on top-right: curves concavely from (W, bodyTop + S) into (W + S, bodyTop)
        PathQuad {
            controlX: root.width
            controlY: root.bodyTop
            x: root.width + root.rightShoulder
            y: root.bodyTop
        }

        // Top edge closing back to start
        PathLine {
            x: -root.leftShoulder
            y: root.bodyTop
        }
    }
}
