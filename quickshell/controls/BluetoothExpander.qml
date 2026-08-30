import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../theme"
import "../components" as Components

Item {
    id: root

    property string targetScreenName: ""
    property string statusMessage: ""

    readonly property bool expanded: UiState.bluetoothVisible
        && (UiState.bluetoothScreen === "" || UiState.bluetoothScreen === targetScreenName)
    
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool isPowered: adapter ? adapter.enabled : false
    readonly property bool isDiscovering: adapter ? adapter.discovering : false

    readonly property var allDevices: {
        if (!Bluetooth.devices || !Bluetooth.devices.values) return []
        return Bluetooth.devices.values
    }

    readonly property var pairedDevices: {
        return allDevices.filter(d => d && (d.paired || d.bonded || d.connected)).sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            const nameA = a.name || a.deviceName || a.address || ""
            const nameB = b.name || b.deviceName || b.address || ""
            return nameA.localeCompare(nameB)
        })
    }

    readonly property var availableDevices: {
        return allDevices.filter(d => d && !d.paired && !d.bonded && !d.connected && (d.name || d.deviceName)).sort((a, b) => {
            const nameA = a.name || a.deviceName || a.address || ""
            const nameB = b.name || b.deviceName || b.address || ""
            return nameA.localeCompare(nameB)
        })
    }

    readonly property var connectedDevice: {
        return allDevices.find(d => d && d.connected) || null
    }

    readonly property var combinedList: {
        const list = []
        for (let i = 0; i < pairedDevices.length; i++) {
            list.push({ device: pairedDevices[i], isPaired: true })
        }
        for (let j = 0; j < availableDevices.length; j++) {
            list.push({ device: availableDevices[j], isPaired: false })
        }
        return list
    }

    readonly property int bodyHeight: !isPowered ? 160 : 352
    property real reveal: expanded ? 1 : 0

    property real expandedWidth: 350
    implicitWidth: expanded || reveal > 0 ? expandedWidth : Theme.compactPillSize
    implicitHeight: reveal > 0
        ? Theme.barHeight + Theme.outerGap + bodyHeight * reveal
        : Theme.barHeight
    focus: expanded

    Behavior on reveal {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate }
    }

    onExpandedChanged: {
        if (expanded) {
            if (adapter && isPowered) adapter.discovering = true
            Qt.callLater(() => root.forceActiveFocus())
        } else {
            if (adapter) adapter.discovering = false
            statusMessage = ""
        }
    }

    function close() {
        UiState.bluetoothVisible = false
    }

    function toggle() {
        UiState.toggleBluetooth(targetScreenName)
    }

    function getDeviceIcon(device) {
        if (!device) return "󰂯"
        const icon = (device.icon || "").toLowerCase()
        const name = (device.name || device.deviceName || "").toLowerCase()
        
        if (name.indexOf("tv") !== -1 || icon.indexOf("tv") !== -1)
            return "󰟴"
        if (icon.indexOf("headset") !== -1 || icon.indexOf("headphones") !== -1 || name.indexOf("headphone") !== -1 || name.indexOf("wh-1000") !== -1 || name.indexOf("airpods") !== -1 || name.indexOf("buds") !== -1 || name.indexOf("earphone") !== -1 || name.indexOf("m71") !== -1)
            return "󰋋"
        if (icon.indexOf("audio") !== -1 || icon.indexOf("speaker") !== -1 || name.indexOf("speaker") !== -1 || name.indexOf("soundbar") !== -1)
            return "󰓃"
        if (icon.indexOf("keyboard") !== -1 || name.indexOf("keyboard") !== -1)
            return "󰌌"
        if (icon.indexOf("mouse") !== -1 || name.indexOf("mouse") !== -1 || name.indexOf("trackpad") !== -1)
            return "󰍽"
        if (icon.indexOf("phone") !== -1 || name.indexOf("phone") !== -1 || name.indexOf("iphone") !== -1 || name.indexOf("galaxy") !== -1 || name.indexOf("pixel") !== -1 || name.indexOf("pixd") !== -1)
            return "󰏲"
        if (icon.indexOf("computer") !== -1 || icon.indexOf("laptop") !== -1)
            return "󰌢"
        if (icon.indexOf("gamepad") !== -1 || icon.indexOf("controller") !== -1 || name.indexOf("controller") !== -1 || name.indexOf("dualsense") !== -1)
            return "󰊴"
        
        return "󰂯"
    }

    function bluetoothIcon() {
        if (!adapter || !isPowered)
            return "󰂲"
        if (connectedDevice)
            return "󰂱"
        return "󰂯"
    }

    Keys.onEscapePressed: close()

    Components.ConnectedDropdownSurface {
        z: 1
        anchors.fill: parent
        hasLeftShoulder: true
        hasRightShoulder: false
        hasBottomRightInverted: true
        visible: root.reveal > 0
    }

    Components.Pill {
        z: 2
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight
        visible: root.reveal <= 0
    }

    Item {
        z: 3
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight

        Text {
            anchors.centerIn: parent
            text: root.bluetoothIcon()
            color: !root.adapter || !root.isPowered 
                ? Theme.fgMuted 
                : (root.connectedDevice ? Theme.blue : Theme.fg)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                } else {
                    root.toggle()
                }
            }
        }
    }

    Rectangle {
        z: 2
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bodyHeight * root.reveal
        visible: height > 0
        opacity: Math.max(0.0, Math.min(1.0, (root.reveal - 0.15) / 0.85))
        color: "transparent"
        border.width: 0
        clip: true

        Item {
            anchors.top: parent.top
            width: parent.width
            height: root.bodyHeight

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: root.isDiscovering ? "󰑐" : "󰂯"
                            color: root.isDiscovering ? Theme.accent : (scanHover.hovered ? Theme.accent : Theme.blue)
                            font.family: Theme.fontFamily
                            font.pixelSize: 16

                            RotationAnimation on rotation {
                                running: root.isDiscovering
                                from: 0; to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.statusMessage !== "" ? root.statusMessage
                                : (root.isDiscovering ? "Scanning..." : "Bluetooth")
                            color: root.statusMessage !== "" ? Theme.red
                                : (scanHover.hovered ? Theme.accent : Theme.fg)
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 14
                            font.weight: Theme.fontWeight
                            elide: Text.ElideRight
                        }

                        HoverHandler { id: scanHover; enabled: root.isPowered && root.statusMessage === "" }
                        TapHandler {
                            enabled: root.isPowered && root.statusMessage === ""
                            onTapped: {
                                if (root.adapter) {
                                    root.adapter.discovering = !root.adapter.discovering
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.preferredWidth: 62
                        Layout.preferredHeight: 26
                        Text {
                            text: root.isPowered ? "On" : "Off"
                            color: root.isPowered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                        }
                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 18
                            radius: height / 2
                            color: root.isPowered ? Theme.accent : Theme.surface

                            Rectangle {
                                width: 14
                                height: 14
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.isPowered ? parent.width - width - 2 : 2
                                color: root.isPowered ? Theme.bgDark : Theme.fgDim

                                Behavior on x {
                                    NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                                }
                            }

                            HoverHandler { id: powerToggleHover }
                            TapHandler {
                                onTapped: {
                                    if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                                }
                            }
                        }
                    }

                    Text {
                        text: "󰅖"
                        color: closeHover.hovered ? Theme.red : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        HoverHandler { id: closeHover }
                        TapHandler { onTapped: root.close() }
                    }
                }

                // Adapter off state
                Rectangle {
                    visible: !root.adapter || !root.isPowered
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSmall
                    color: Theme.bgLight

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰂲"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 32
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: !root.adapter ? "No Bluetooth Adapter" : "Bluetooth is off"
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                        }

                        Rectangle {
                            visible: root.adapter !== null && !root.isPowered
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: turnOnText.implicitWidth + 20
                            implicitHeight: 28
                            radius: Theme.radiusSmall
                            color: turnOnHover.hovered ? Theme.accentGlow : Theme.accent

                            Text {
                                id: turnOnText
                                anchors.centerIn: parent
                                text: "Turn On"
                                color: Theme.bgDark
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 13
                                font.weight: Theme.fontWeightBold
                            }

                            HoverHandler { id: turnOnHover }
                            TapHandler {
                                onTapped: {
                                    if (root.adapter) root.adapter.enabled = true
                                }
                            }
                        }
                    }
                }

                // Device list
                ListView {
                    id: devList
                    visible: root.adapter !== null && root.isPowered
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 80
                    model: root.combinedList
                    clip: true
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: devDelegate
                        required property var modelData
                        readonly property var dev: modelData.device
                        readonly property bool isPaired: modelData.isPaired

                        width: ListView.view.width
                        height: 48
                        radius: Theme.radiusSmall
                        color: dev.connected ? Theme.accent
                            : (devHover.hovered ? Theme.surface : Theme.bgLight)

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: root.getDeviceIcon(devDelegate.dev)
                                color: devDelegate.dev.connected ? Theme.bgDark : Theme.blue
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: devDelegate.dev.name || devDelegate.dev.deviceName || devDelegate.dev.address
                                    color: devDelegate.dev.connected ? Theme.bgDark : Theme.fg
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Theme.fontWeight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: {
                                        let status = devDelegate.dev.connected ? "Connected"
                                            : (devDelegate.dev.state === BluetoothDeviceState.Connecting ? "Connecting..."
                                            : (devDelegate.isPaired ? "Paired" : (devDelegate.dev.pairing ? "Pairing..." : "Available")))
                                        if (devDelegate.dev.batteryAvailable)
                                            status += " · 󰁹 " + Math.round(devDelegate.dev.battery * 100) + "%"
                                        return status
                                    }
                                    color: devDelegate.dev.connected ? Theme.bgDark : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                }
                            }

                            // Connect/disconnect for paired, Pair for unpaired
                            Text {
                                visible: devDelegate.isPaired
                                text: devDelegate.dev.connected ? "󰅖" : "󰄬"
                                color: devDelegate.dev.connected ? Theme.bgDark : Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }

                            Rectangle {
                                visible: !devDelegate.isPaired
                                implicitWidth: pairLabel.implicitWidth + 14
                                implicitHeight: 24
                                radius: Theme.radiusSmall
                                color: pairHov.hovered ? Theme.accentGlow : Theme.accent

                                Text {
                                    id: pairLabel
                                    anchors.centerIn: parent
                                    text: devDelegate.dev.pairing ? "Pairing" : "Pair"
                                    color: Theme.bgDark
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Theme.fontWeightBold
                                }

                                HoverHandler { id: pairHov }
                                TapHandler { onTapped: devDelegate.dev.pair() }
                            }
                        }

                        HoverHandler { id: devHover }
                        TapHandler {
                            onTapped: {
                                if (devDelegate.isPaired) {
                                    if (devDelegate.dev.connected)
                                        devDelegate.dev.disconnect()
                                    else
                                        devDelegate.dev.connect()
                                } else {
                                    devDelegate.dev.pair()
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: devList.count === 0
                        text: root.isDiscovering ? "Searching for devices…" : "No devices found"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                }

                // Footer actions
                RowLayout {
                    visible: root.adapter !== null && root.isPowered
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    spacing: 8

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰇮"
                            color: sendHov.hovered ? Theme.accent : Theme.blue
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Send Files"
                            color: sendHov.hovered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                        }
                        HoverHandler { id: sendHov }
                        TapHandler {
                            onTapped: Quickshell.execDetached(["blueman-sendto"])
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰒓"
                            color: settingsHov.hovered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Settings"
                            color: settingsHov.hovered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                        }
                        HoverHandler { id: settingsHov }
                        TapHandler {
                            onTapped: Quickshell.execDetached(["blueman-manager"])
                        }
                    }
                }
            }
        }
    }
}
