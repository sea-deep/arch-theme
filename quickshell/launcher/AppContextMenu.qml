import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Rectangle {
    id: root

    property var app: null
    property var actionsList: []
    signal actionTriggered()

    width: 220
    implicitHeight: layout.implicitHeight + 16
    radius: Theme.radius
    color: Theme.bg
    border.color: Theme.surfaceVariant
    border.width: 1
    clip: true

    opacity: visible ? 1 : 0
    scale: visible ? 1 : 0.95
    transformOrigin: Item.TopLeft

    Behavior on opacity { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingDecelerate } }
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingEmphasized; easing.overshoot: 1.08 } }

    onAppChanged: {
        var list = []
        if (app) {
            // Check for Desktop Actions in the desktop entry
            if (app.actions) {
                var actCount = typeof app.actions.length !== "undefined" ? app.actions.length : (app.actions.values ? app.actions.values.length : 0)
                var actArr = app.actions.values || app.actions
                for (var i = 0; i < actCount; i++) {
                    var a = actArr[i]
                    if (a && a.name) {
                        list.push({
                            name: a.name,
                            icon: "󰅂",
                            type: "action",
                            actionObj: a
                        })
                    }
                }
            }
        }
        actionsList = list
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: {}
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        // App header in context menu
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.app ? (root.app.name || "Application") : "Application"
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: 12
                font.weight: Theme.fontWeight
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.surface
        }

            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: openHover.containsMouse ? Theme.bgLight : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: ""
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: "Launch"
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: openHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.app) {
                        if (root.app.runInTerminal) {
                            var execCmd = root.app.execString || (root.app.command ? (typeof root.app.command.join === "function" ? root.app.command.join(" ") : root.app.command) : root.app.id)
                            execCmd = execCmd.replace(/%[a-zA-Z]/g, "").trim()
                            Quickshell.execDetached(["kitty", "-e", "sh", "-c", execCmd])
                        } else if (root.app.execute) {
                            root.app.execute()
                        } else if (root.app.execString) {
                            var cmd = root.app.execString.replace(/%[a-zA-Z]/g, "").trim()
                            Quickshell.execDetached(["sh", "-c", cmd])
                        }
                    }
                    root.actionTriggered()
                }
            }
        }

        // 2. Desktop Actions (e.g. Incognito, New Window)
        Repeater {
            model: root.actionsList

            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: actHover.containsMouse ? Theme.bgLight : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "󰅂"
                        color: Theme.purple
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                    Text {
                        text: modelData.name
                        color: Theme.fg
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: actHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.actionObj && modelData.actionObj.execute) {
                            modelData.actionObj.execute()
                        } else if (root.app && root.app.executeAction) {
                            root.app.executeAction(modelData.actionObj.id || modelData.actionObj.name)
                        }
                        root.actionTriggered()
                    }
                }
            }
        }

        // 3. Run in Terminal (via Kitty)
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 6
            color: termHover.containsMouse ? Theme.bgLight : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: ""
                    color: Theme.yellow
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: "Run in Terminal"
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: termHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.app) {
                        var execCmd = root.app.execString || root.app.id || ""
                        execCmd = execCmd.replace(/%[a-zA-Z]/g, "").trim()
                        if (execCmd) {
                            Quickshell.execDetached(["kitty", "-e", "bash", "-c", execCmd + "; exec bash"])
                        } else if (root.app.execute) {
                            root.app.execute()
                        }
                    }
                    root.actionTriggered()
                }
            }
        }

        // 4. Launch with Dedicated GPU
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 6
            color: dgpuHover.containsMouse ? Theme.bgLight : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: "󰢮"
                    color: Theme.green
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
                Text {
                    text: "Run with Discrete GPU"
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: dgpuHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.app) {
                        var execCmd = root.app.execString || root.app.id || ""
                        execCmd = execCmd.replace(/%[a-zA-Z]/g, "").trim()
                        if (execCmd) {
                            Quickshell.execDetached(["env", "DRI_PRIME=1", "__NV_PRIME_RENDER_OFFLOAD=1", "__GLX_VENDOR_LIBRARY_NAME=nvidia", "bash", "-c", execCmd])
                        } else if (root.app.execute) {
                            root.app.execute()
                        }
                    }
                    root.actionTriggered()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.surface
        }

        // 5. Uninstall App
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 6
            color: uninstallHover.containsMouse ? Theme.bgLight : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                IconImage {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: Quickshell.iconPath("user-trash", "application-x-executable")
                }
                Text {
                    text: "Uninstall App"
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: uninstallHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.app) {
                        var execCmd = root.app.execString || root.app.id || ""
                        if (execCmd) {
                            var scriptPath = Quickshell.env("HOME") + "/.config/hypr/scripts/uninstall_app.sh"
                            Quickshell.execDetached(["kitty", "--title", "Uninstall App", "bash", scriptPath, execCmd, root.app.id || ""])
                        }
                    }
                    root.actionTriggered()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.surface
        }

        // 6. Copy Command
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 6
            color: copyHover.containsMouse ? Theme.bgLight : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: "󰅍"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: "Copy Exec Command"
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: copyHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.app) {
                        var execCmd = root.app.execString || root.app.id || ""
                        execCmd = execCmd.replace(/%[a-zA-Z]/g, "").trim()
                        Quickshell.execDetached(["wl-copy", execCmd])
                    }
                    root.actionTriggered()
                }
            }
        }
    }
}
