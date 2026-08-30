import QtQuick
import QtQuick.Shapes
import "../theme"

Shape {
    id: root

    property color fillColor: Theme.bg
    property real shoulderRadius: 14
    property real cornerRadius: Theme.radius
    property real bodyTop: Theme.barHeight
    property bool hasLeftShoulder: true
    property bool hasRightShoulder: true
    property bool hasBottomRightInverted: false
    property bool hasBottomLeftInverted: false

    // Compatibility properties
    property real tabWidth: Theme.compactPillSize
    property bool tabOnLeft: false
    property bool tabCentered: false

    readonly property real leftExt: hasLeftShoulder ? shoulderRadius : 0
    readonly property real rightExt: hasRightShoulder ? shoulderRadius : 0
    readonly property real botLeftExt: hasBottomLeftInverted ? shoulderRadius : 0
    readonly property real botRightExt: hasBottomRightInverted ? shoulderRadius : 0

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillColor
        joinStyle: ShapePath.RoundJoin

        // 1. Start at top-left shoulder along the bar bottom line
        startX: -root.leftExt
        startY: root.bodyTop

        // 2. Top-Left Inverted Fillet Shoulder (concave curve into left vertical wall)
        PathQuad {
            controlX: 0
            controlY: root.bodyTop
            x: 0
            y: root.bodyTop + root.leftExt
        }

        // 3. Left vertical wall down to bottom-left corner
        PathLine {
            x: 0
            y: root.hasBottomLeftInverted
                ? (root.height + root.botLeftExt)
                : Math.max(root.bodyTop + root.leftExt, root.height - root.cornerRadius)
        }

        // 4. Bottom-Left corner (concave inverted fillet if enabled, else convex rounded)
        PathQuad {
            controlX: 0
            controlY: root.height
            x: root.hasBottomLeftInverted ? root.botLeftExt : Math.min(root.cornerRadius, root.width / 2)
            y: root.height
        }

        // 5. Bottom horizontal edge
        PathLine {
            x: root.hasBottomRightInverted
                ? Math.max(root.cornerRadius, root.width - root.botRightExt)
                : Math.max(root.cornerRadius, root.width - root.cornerRadius)
            y: root.height
        }

        // 6. Bottom-Right corner (concave inverted fillet if enabled, else convex rounded)
        PathQuad {
            controlX: root.width
            controlY: root.height
            x: root.width
            y: root.hasBottomRightInverted
                ? (root.height + root.botRightExt)
                : Math.max(root.bodyTop + root.rightExt, root.height - root.cornerRadius)
        }

        // 7. Right vertical wall up to top-right shoulder
        PathLine {
            x: root.width
            y: root.bodyTop + root.rightExt
        }

        // 8. Top-Right Inverted Fillet Shoulder (concave curve out into the bar bottom)
        PathQuad {
            controlX: root.width
            controlY: root.bodyTop
            x: root.width + root.rightExt
            y: root.bodyTop
        }

        // 9. Top edge along the bar bottom closing back to start
        PathLine {
            x: -root.leftExt
            y: root.bodyTop
        }
    }
}
