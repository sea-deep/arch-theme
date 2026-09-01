import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root
    WlrLayershell.namespace: "screenshot-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    margins.top: 0
    margins.bottom: 0
    margins.left: 0
    margins.right: 0
    color: "transparent"

    property bool showing: UiState.screenshotVisible
    property real reveal: showing ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    visible: reveal > 0

    property string currentMode: "crop" // "crop" | "window"
    property bool isDragging: false
    property real startX: 0
    property real startY: 0
    property real curX: 0
    property real curY: 0
    property var hoveredWin: null
    property var windowsList: []

    readonly property real selX: Math.min(startX, curX)
    readonly property real selY: Math.min(startY, curY)
    readonly property real selW: Math.abs(curX - startX)
    readonly property real selH: Math.abs(curY - startY)

    Process {
        id: winProc
        command: ["sh", "-c", "hyprctl clients -j | jq -c '.'"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data);
                    var activeWsId = 1;
                    if (Hyprland.focusedWorkspace) activeWsId = Hyprland.focusedWorkspace.id;
                    var filtered = [];
                    for (var i = 0; i < parsed.length; i++) {
                        var w = parsed[i];
                        if (w.mapped && !w.hidden && w.workspace && (w.workspace.id === activeWsId || w.floating)) {
                            filtered.push(w);
                        }
                    }
                    root.windowsList = filtered;
                } catch(e) {}
            }
        }
    }

    onShowingChanged: {
        if (showing) {
            currentMode = "crop"
            isDragging = false
            startX = 0
            startY = 0
            curX = 0
            curY = 0
            hoveredWin = null
            winProc.running = true
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.showing
        onActivated: UiState.screenshotVisible = false
    }

    Shortcut {
        sequence: "f"
        enabled: root.showing
        onActivated: root.captureFull()
    }

    Shortcut {
        sequence: "Shift+F"
        enabled: root.showing
        onActivated: root.captureFull()
    }

    Shortcut {
        sequence: "w"
        enabled: root.showing
        onActivated: {
            root.currentMode = (root.currentMode === "window" ? "crop" : "window")
            if (root.currentMode === "window") winProc.running = true
        }
    }

    Shortcut {
        sequence: "Shift+W"
        enabled: root.showing
        onActivated: {
            root.currentMode = (root.currentMode === "window" ? "crop" : "window")
            if (root.currentMode === "window") winProc.running = true
        }
    }

    Shortcut {
        sequence: "r"
        enabled: root.showing
        onActivated: root.currentMode = "crop"
    }

    Shortcut {
        sequence: "c"
        enabled: root.showing
        onActivated: root.currentMode = "crop"
    }

    function captureFull() {
        UiState.screenshotVisible = false
        var script = Quickshell.env("HOME") + "/.config/hypr/screenshot.sh"
        Quickshell.execDetached(["bash", script, "full"])
    }

    function captureRegion(geom) {
        UiState.screenshotVisible = false
        var script = Quickshell.env("HOME") + "/.config/hypr/screenshot.sh"
        Quickshell.execDetached(["bash", script, "region", geom])
    }

    // ── Static Frozen Desktop Snapshot Background (KDE Spectacle Architecture) ──
    Image {
        id: freezeBg
        anchors.fill: parent
        source: root.showing ? ("file:///tmp/qs_screenshot_freeze.ppm?" + UiState.freezeTimestamp) : ""
        fillMode: Image.Stretch
        cache: false
        asynchronous: false
        z: 0
    }

    // ── Mouse Area for Region & Window Selection ──
    MouseArea {
        id: mainMouse
        anchors.fill: parent
        z: 3
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.currentMode === "window" ? Qt.PointingHandCursor : Qt.CrossCursor

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                UiState.screenshotVisible = false
                return
            }
            if (root.currentMode === "window") {
                if (root.hoveredWin) {
                    var geom = root.hoveredWin.at[0] + "," + root.hoveredWin.at[1] + " " + root.hoveredWin.size[0] + "x" + root.hoveredWin.size[1]
                    root.captureRegion(geom)
                }
            } else {
                root.isDragging = true
                root.startX = mouse.x
                root.startY = mouse.y
                root.curX = mouse.x
                root.curY = mouse.y
            }
        }

        onPositionChanged: mouse => {
            if (root.currentMode === "window") {
                var found = null
                for (var i = 0; i < root.windowsList.length; i++) {
                    var w = root.windowsList[i]
                    if (mouse.x >= w.at[0] && mouse.x <= w.at[0] + w.size[0] &&
                        mouse.y >= w.at[1] && mouse.y <= w.at[1] + w.size[1]) {
                        found = w
                        break
                    }
                }
                root.hoveredWin = found
            } else if (root.isDragging) {
                root.curX = mouse.x
                root.curY = mouse.y
            }
        }

        onReleased: mouse => {
            if (root.currentMode === "crop" && root.isDragging) {
                root.isDragging = false
                var x = Math.min(root.startX, root.curX)
                var y = Math.min(root.startY, root.curY)
                var w = Math.abs(root.curX - root.startX)
                var h = Math.abs(root.curY - root.startY)
                if (w > 10 && h > 10) {
                    var geom = Math.round(x) + "," + Math.round(y) + " " + Math.round(w) + "x" + Math.round(h)
                    root.captureRegion(geom)
                }
            }
        }
    }

    // ── Semi-Transparent Shroud / Cutout System ──
    Item {
        anchors.fill: parent
        z: 1

        // 1. Crop Mode Shroud (Cutout around dragged rectangle)
        Item {
            anchors.fill: parent
            visible: root.currentMode === "crop"

            // Fullscreen dark overlay when not dragging
            Rectangle {
                anchors.fill: parent
                visible: !root.isDragging || root.selW <= 2 || root.selH <= 2
                color: Qt.rgba(0, 0, 0, 0.45)
            }

            // 4 Cutout rectangles when dragging
            Item {
                anchors.fill: parent
                visible: root.isDragging && root.selW > 2 && root.selH > 2

                Rectangle { // Top
                    x: 0; y: 0; width: root.width; height: Math.max(0, root.selY)
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
                Rectangle { // Bottom
                    x: 0; y: root.selY + root.selH; width: root.width; height: Math.max(0, root.height - (root.selY + root.selH))
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
                Rectangle { // Left
                    x: 0; y: root.selY; width: Math.max(0, root.selX); height: root.selH
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
                Rectangle { // Right
                    x: root.selX + root.selW; y: root.selY; width: Math.max(0, root.width - (root.selX + root.selW)); height: root.selH
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
            }
        }

        // 2. Window Mode Shroud (Cutout around hovered window)
        Item {
            anchors.fill: parent
            visible: root.currentMode === "window"

            Rectangle {
                anchors.fill: parent
                visible: root.hoveredWin === null
                color: Qt.rgba(0, 0, 0, 0.45)
            }

            Item {
                anchors.fill: parent
                visible: root.hoveredWin !== null

                Rectangle { // Top
                    x: 0; y: 0; width: root.width
                    height: root.hoveredWin ? Math.max(0, root.hoveredWin.at[1]) : 0
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
                Rectangle { // Bottom
                    x: 0
                    y: root.hoveredWin ? root.hoveredWin.at[1] + root.hoveredWin.size[1] : 0
                    width: root.width
                    height: root.hoveredWin ? Math.max(0, root.height - (root.hoveredWin.at[1] + root.hoveredWin.size[1])) : 0
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
                Rectangle { // Left
                    x: 0
                    y: root.hoveredWin ? root.hoveredWin.at[1] : 0
                    width: root.hoveredWin ? Math.max(0, root.hoveredWin.at[0]) : 0
                    height: root.hoveredWin ? root.hoveredWin.size[1] : 0
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
                Rectangle { // Right
                    x: root.hoveredWin ? root.hoveredWin.at[0] + root.hoveredWin.size[0] : 0
                    y: root.hoveredWin ? root.hoveredWin.at[1] : 0
                    width: root.hoveredWin ? Math.max(0, root.width - (root.hoveredWin.at[0] + root.hoveredWin.size[0])) : 0
                    height: root.hoveredWin ? root.hoveredWin.size[1] : 0
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
            }
        }
    }

    // ── Active Crop Selection Rectangle ──
    Rectangle {
        z: 2
        visible: root.currentMode === "crop" && root.isDragging && root.selW > 2 && root.selH > 2
        x: root.selX
        y: root.selY
        width: root.selW
        height: root.selH
        color: "transparent"
        border.color: Theme.accent
        border.width: 2

        // Dimension Badge
        Rectangle {
            anchors.bottom: parent.top
            anchors.bottomMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            height: 24
            implicitWidth: dimText.implicitWidth + 16
            radius: 12
            color: Theme.bg
            border.color: Theme.accentGlow
            border.width: 1

            Text {
                id: dimText
                anchors.centerIn: parent
                text: Math.round(root.selW) + " × " + Math.round(root.selH) + " px"
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: 11
                font.weight: Theme.fontWeight
            }
        }
    }

    // ── Active Hovered Window Rectangle ──
    Rectangle {
        z: 2
        visible: root.currentMode === "window" && root.hoveredWin !== null
        x: root.hoveredWin ? root.hoveredWin.at[0] : 0
        y: root.hoveredWin ? root.hoveredWin.at[1] : 0
        width: root.hoveredWin ? root.hoveredWin.size[0] : 0
        height: root.hoveredWin ? root.hoveredWin.size[1] : 0
        color: "transparent"
        border.color: Theme.accent
        border.width: 2

        // Window Info Badge
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            height: 24
            implicitWidth: winInfoText.implicitWidth + 16
            radius: 12
            color: Theme.bg
            border.color: Theme.accentGlow
            border.width: 1

            Text {
                id: winInfoText
                anchors.centerIn: parent
                text: (root.hoveredWin ? ((root.hoveredWin.title || root.hoveredWin.class) + " • " + root.hoveredWin.size[0] + "×" + root.hoveredWin.size[1] + " px") : "")
                color: Theme.accent
                font.family: Theme.fontFamilySans
                font.pixelSize: 11
                font.weight: Theme.fontWeight
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    // ── Top Floating HUD Control Capsule (Concentric Radius Math: R_outer = R_inner + Padding) ──
    Rectangle {
        id: hudCapsule
        z: 10
        anchors.top: parent.top
        anchors.topMargin: 48
        anchors.horizontalCenter: parent.horizontalCenter
        height: 42
        width: hudRow.implicitWidth + 10
        radius: 21
        color: Theme.bg
        border.color: Theme.accentGlow
        border.width: Theme.borderWidth

        // Automatically hide the HUD capsule when dragging to snip a region
        opacity: root.isDragging ? 0.0 : 1.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        Row {
            id: hudRow
            anchors.centerIn: parent
            spacing: 4

            // Drag Region Button
            Rectangle {
                id: snipBtn
                height: 32
                width: snipText.implicitWidth + 24
                radius: 16
                color: root.currentMode === "crop" ? Theme.accent : (snipHover.containsMouse ? Theme.bgLight : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    id: snipText
                    anchors.centerIn: parent
                    text: "󰆞  Drag Region"
                    color: root.currentMode === "crop" ? Theme.bgDark : Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    font.weight: Theme.fontWeight
                }

                MouseArea {
                    id: snipHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.currentMode = "crop"
                }
            }

            // Window Selection Button
            Rectangle {
                id: winBtn
                height: 32
                width: winText.implicitWidth + 24
                radius: 16
                color: root.currentMode === "window" ? Theme.accent : (winHover.containsMouse ? Theme.bgLight : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    id: winText
                    anchors.centerIn: parent
                    text: "󰖲  Window (W)"
                    color: root.currentMode === "window" ? Theme.bgDark : Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    font.weight: Theme.fontWeight
                }

                MouseArea {
                    id: winHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.currentMode = "window"
                        winProc.running = true
                    }
                }
            }

            // Fullscreen Button
            Rectangle {
                id: fullBtn
                height: 32
                width: fullText.implicitWidth + 24
                radius: 16
                color: fullHover.containsMouse ? Theme.bgLight : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    id: fullText
                    anchors.centerIn: parent
                    text: "󰍹  Fullscreen (F)"
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    font.weight: Theme.fontWeight
                }

                MouseArea {
                    id: fullHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.captureFull()
                }
            }

            // Subtle Separator
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 16
                color: Theme.surfaceVariant
            }

            // Cancel Button
            Rectangle {
                id: cancelBtn
                height: 32
                width: cancelText.implicitWidth + 20
                radius: 16
                color: cancelHover.containsMouse ? Theme.bgLight : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: "󱊷  Esc"
                    color: Theme.fgDim
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    font.weight: Theme.fontWeight
                }

                MouseArea {
                    id: cancelHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: UiState.screenshotVisible = false
                }
            }
        }
    }
}
