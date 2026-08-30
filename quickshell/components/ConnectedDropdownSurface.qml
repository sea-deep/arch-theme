import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property color fillColor: Theme.bgLight
    property real tabWidth: Theme.compactPillSize
    property bool tabOnLeft: false
    property bool tabCentered: false
    readonly property real bodyTop: Theme.barHeight
    readonly property real bodyExtent: Math.max(0, height - bodyTop)
    readonly property real bodyCorner: Math.min(Theme.radius, bodyExtent / 2)
    readonly property real effectiveTabWidth: Math.min(width, Math.max(Theme.compactPillSize, tabWidth))
    readonly property real tabLeft: tabCentered
        ? (width - effectiveTabWidth) / 2
        : (tabOnLeft ? 0 : width - effectiveTabWidth)
    readonly property real shoulder: Math.min(Theme.radius, Math.max(0, width - effectiveTabWidth) / 2)

    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
        origin.x: root.width / 2
        xScale: (root.tabOnLeft && !root.tabCentered) ? -1 : 1
    }

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillColor
        joinStyle: ShapePath.RoundJoin

        // CASE A: Centered tab (shoulders on both sides)
        // CASE B: Tab on right (or flipped for tab on left)
        startX: root.tabCentered
            ? (root.tabLeft + Theme.radius)
            : (root.width - root.effectiveTabWidth + Theme.radius)
        startY: 0

        // 1. Top of tab
        PathLine {
            x: root.tabCentered
                ? (root.tabLeft + root.effectiveTabWidth - Theme.radius)
                : (root.width - Theme.radius)
            y: 0
        }

        // 2. Top-right corner of tab
        PathQuad {
            controlX: root.tabCentered ? (root.tabLeft + root.effectiveTabWidth) : root.width
            controlY: 0
            x: root.tabCentered ? (root.tabLeft + root.effectiveTabWidth) : root.width
            y: Theme.radius
        }

        // 3. Right side of tab down towards body
        PathLine {
            x: root.tabCentered ? (root.tabLeft + root.effectiveTabWidth) : root.width
            y: root.tabCentered ? (root.bodyTop - root.shoulder) : (root.height - root.bodyCorner)
        }

        // 4. (Centered only) Right concave shoulder into dropdown body top
        PathQuad {
            controlX: root.tabCentered ? (root.tabLeft + root.effectiveTabWidth) : root.width
            controlY: root.tabCentered ? root.bodyTop : 0
            x: root.tabCentered ? (root.tabLeft + root.effectiveTabWidth + root.shoulder) : root.width
            y: root.tabCentered ? root.bodyTop : 0
        }

        // 5. (Centered only) Across body top to top-right corner
        PathLine {
            x: root.tabCentered ? (root.width - root.bodyCorner) : root.width
            y: root.tabCentered ? root.bodyTop : (root.height - root.bodyCorner)
        }

        // 6. (Centered only) Top-right corner of body
        PathQuad {
            controlX: root.tabCentered ? root.width : root.width
            controlY: root.tabCentered ? root.bodyTop : root.height
            x: root.tabCentered ? root.width : (root.width - root.bodyCorner)
            y: root.tabCentered ? (root.bodyTop + root.bodyCorner) : root.height
        }

        // 7. Right wall of dropdown body
        PathLine {
            x: root.width
            y: root.height - root.bodyCorner
        }

        // 8. Bottom-right corner
        PathQuad {
            controlX: root.width
            controlY: root.height
            x: root.width - root.bodyCorner
            y: root.height
        }

        // 9. Bottom edge
        PathLine {
            x: root.bodyCorner
            y: root.height
        }

        // 10. Bottom-left corner
        PathQuad {
            controlX: 0
            controlY: root.height
            x: 0
            y: root.height - root.bodyCorner
        }

        // 11. Left wall of dropdown body
        PathLine {
            x: 0
            y: root.bodyTop + root.bodyCorner
        }

        // 12. Top-left corner of dropdown body
        PathQuad {
            controlX: 0
            controlY: root.bodyTop
            x: root.bodyCorner
            y: root.bodyTop
        }

        // 13. Across body top to left concave shoulder
        PathLine {
            x: (root.tabCentered ? root.tabLeft : (root.width - root.effectiveTabWidth)) - root.shoulder
            y: root.bodyTop
        }

        // 14. Concave shoulder curving up into tab left wall
        PathQuad {
            controlX: root.tabCentered ? root.tabLeft : (root.width - root.effectiveTabWidth)
            controlY: root.bodyTop
            x: root.tabCentered ? root.tabLeft : (root.width - root.effectiveTabWidth)
            y: root.bodyTop - root.shoulder
        }

        // 15. Left wall of tab
        PathLine {
            x: root.tabCentered ? root.tabLeft : (root.width - root.effectiveTabWidth)
            y: Theme.radius
        }

        // 16. Top-left corner of tab closing back to start
        PathQuad {
            controlX: root.tabCentered ? root.tabLeft : (root.width - root.effectiveTabWidth)
            controlY: 0
            x: (root.tabCentered ? root.tabLeft : (root.width - root.effectiveTabWidth)) + Theme.radius
            y: 0
        }
    }
}
