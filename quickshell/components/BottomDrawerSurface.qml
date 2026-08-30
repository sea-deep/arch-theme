import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property color fillColor: Theme.bg
    property real shoulderRadius: 14
    property real cornerRadius: Theme.radiusLarge

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillColor
        joinStyle: ShapePath.RoundJoin

        // 1. Start at bottom-left outer wing (along the screen bottom edge)
        startX: -root.shoulderRadius
        startY: root.height

        // 2. Bottom-Left Inverted Fillet (concave curve from bottom edge up into left wall)
        PathQuad {
            controlX: 0
            controlY: root.height
            x: 0
            y: root.height - root.shoulderRadius
        }

        // 3. Left vertical wall up to top-left corner
        PathLine { x: 0; y: root.cornerRadius }

        // 4. Top-Left convex rounded corner
        PathQuad {
            controlX: 0
            controlY: 0
            x: root.cornerRadius
            y: 0
        }

        // 5. Top horizontal edge
        PathLine { x: root.width - root.cornerRadius; y: 0 }

        // 6. Top-Right convex rounded corner
        PathQuad {
            controlX: root.width
            controlY: 0
            x: root.width
            y: root.cornerRadius
        }

        // 7. Right vertical wall down to bottom-right inverted fillet
        PathLine { x: root.width; y: root.height - root.shoulderRadius }

        // 8. Bottom-Right Inverted Fillet (concave curve from right wall out to bottom edge)
        PathQuad {
            controlX: root.width
            controlY: root.height
            x: root.width + root.shoulderRadius
            y: root.height
        }

        // 9. Bottom edge closing back to start
        PathLine { x: -root.shoulderRadius; y: root.height }
    }
}
