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

    readonly property int bodyHeight: !isPowered ? 160 : 380
    property real reveal: expanded ? 1 : 0

    property real expandedWidth: 360
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
            Qt.callLater(() => root.forceActiveFocus())
        } else {
            statusMessage = ""
        }
    }

    function close() {
        UiState.bluetoothVisible = false
    }

    function toggle() {
        UiState.toggleBluetooth(targetScreenName)
    }

    function sendFile(device) {
        const scriptPath = Quickshell.env("HOME") + "/code/arch-theme/quickshell/scripts/bt-send.py"
        if (!device) {
            Quickshell.execDetached(["python3", scriptPath])
        } else {
            const addr = device.address || ""
            if (addr !== "") {
                Quickshell.execDetached(["python3", scriptPath, addr])
            } else {
                Quickshell.execDetached(["python3", scriptPath])
            }
        }
    }

    function openManager() {
        Quickshell.execDetached(["kitty", "--class", "floating_term", "-e", "bluetoothctl"])
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
                anchors.margins: 10
                spacing: 8

                // Header Row (Click title / scan icon to trigger Discovery)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Text {
                            text: root.isDiscovering ? "󰑐" : "󰂯"
                            color: root.isDiscovering ? Theme.accent : (scanHover.hovered ? Theme.accent : Theme.blue)
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            
                            RotationAnimation on rotation {
                                running: root.isDiscovering
                                from: 0; to: 360
                                duration: 1000
                                loops: Animation.Infinite
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.isDiscovering ? "Scanning for devices..." : "Bluetooth"
                            color: scanHover.hovered ? Theme.accent : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 15
                            font.weight: Theme.fontWeightBold
                            elide: Text.ElideRight
                        }

                        HoverHandler { id: scanHover; enabled: root.isPowered }
                        TapHandler {
                            enabled: root.isPowered
                            onTapped: {
                                if (root.adapter) {
                                    root.adapter.discovering = !root.adapter.discovering
                                }
                            }
                        }
                    }

                    // Power Switch
                    RowLayout {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 26
                        spacing: 6

                        Text {
                            text: root.isPowered ? "On" : "Off"
                            color: root.isPowered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 11
                            font.weight: Theme.fontWeight
                        }

                        Rectangle {
                            id: powerSwitch
                            Layout.preferredWidth: 32
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

                // Adapter unavailable or disabled state
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
                            text: !root.adapter ? "No Bluetooth Adapter Found" : "Bluetooth is turned off"
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 13
                            font.weight: Theme.fontWeight
                        }

                        Rectangle {
                            visible: root.adapter !== null && !root.isPowered
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: turnOnText.implicitWidth + 24
                            implicitHeight: 30
                            radius: 6
                            color: turnOnHover.hovered ? Theme.accentGlow : Theme.accent

                            Text {
                                id: turnOnText
                                anchors.centerIn: parent
                                text: "Turn On"
                                color: Theme.bgDark
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 12
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

                // Main Device List
                ListView {
                    id: devList
                    visible: root.adapter !== null && root.isPowered
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 80
                    model: root.combinedList
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds

                    header: Item {
                        width: devList.width
                        height: root.pairedDevices.length > 0 ? 22 : 0
                        visible: root.pairedDevices.length > 0

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: "PAIRED DEVICES"
                            color: Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 11
                            font.weight: Theme.fontWeightBold
                        }
                    }

                    delegate: Rectangle {
                        id: devDelegate
                        required property var modelData
                        readonly property var dev: modelData.device
                        readonly property bool isPaired: modelData.isPaired

                        width: ListView.view.width
                        height: 52
                        radius: Theme.radiusSmall
                        color: dev.connected ? Theme.accent
                            : (devHover.hovered ? Theme.surface : Theme.bgLight)
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 10

                            Text {
                                text: root.getDeviceIcon(devDelegate.dev)
                                color: devDelegate.dev.connected ? Theme.bgDark : Theme.blue
                                font.family: Theme.fontFamily
                                font.pixelSize: 22
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: devDelegate.dev.name || devDelegate.dev.deviceName || devDelegate.dev.address
                                    color: devDelegate.dev.connected ? Theme.bgDark : Theme.fg
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 13.5
                                    font.weight: Theme.fontWeight
                                }

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: devDelegate.dev.connected ? "Connected" 
                                            : (devDelegate.dev.state === BluetoothDeviceState.Connecting ? "Connecting..." 
                                            : (devDelegate.isPaired ? "Paired" : (devDelegate.dev.pairing ? "Pairing..." : "Ready to pair")))
                                        color: devDelegate.dev.connected ? Theme.bgDark : Theme.fgDim
                                        font.family: Theme.fontFamilySans
                                        font.pixelSize: 10.5
                                    }

                                    Text {
                                        visible: devDelegate.dev.batteryAvailable
                                        text: "· 󰁹 " + Math.round(devDelegate.dev.battery * 100) + "%"
                                        color: devDelegate.dev.connected ? Theme.bgDark : Theme.fgDim
                                        font.family: Theme.fontFamilySans
                                        font.pixelSize: 10.5
                                    }
                                }
                            }

                            // Paired quick action icon buttons
                            RowLayout {
                                visible: devDelegate.isPaired
                                spacing: 4

                                // Send File
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: sfHov.hovered 
                                        ? (devDelegate.dev.connected ? Qt.rgba(0, 0, 0, 0.25) : Theme.surfaceVariant)
                                        : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰇮"
                                        color: devDelegate.dev.connected ? Theme.bgDark : Theme.blue
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                    }

                                    HoverHandler { id: sfHov }
                                    TapHandler {
                                        onTapped: root.sendFile(devDelegate.dev)
                                    }
                                }

                                // Forget / Unpair
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: fgHov.hovered 
                                        ? (devDelegate.dev.connected ? Qt.rgba(0, 0, 0, 0.25) : Theme.surfaceVariant)
                                        : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        color: devDelegate.dev.connected ? Theme.bgDark : Theme.fgDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                    }

                                    HoverHandler { id: fgHov }
                                    TapHandler {
                                        onTapped: devDelegate.dev.forget()
                                    }
                                }

                                // Connect / Disconnect Action Icon
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: connHov.hovered 
                                        ? (devDelegate.dev.connected ? Qt.rgba(0, 0, 0, 0.25) : Theme.surfaceVariant)
                                        : (devDelegate.dev.connected ? Qt.rgba(0, 0, 0, 0.12) : Theme.surface)

                                    Text {
                                        anchors.centerIn: parent
                                        text: devDelegate.dev.connected ? "󰅖" : "󰄬"
                                        color: devDelegate.dev.connected ? Theme.bgDark : Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                    }

                                    HoverHandler { id: connHov }
                                    TapHandler {
                                        onTapped: {
                                            if (devDelegate.dev.connected) {
                                                devDelegate.dev.disconnect()
                                            } else {
                                                devDelegate.dev.connect()
                                            }
                                        }
                                    }
                                }
                            }

                            // Unpaired Pair button
                            Rectangle {
                                visible: !devDelegate.isPaired
                                implicitWidth: pairBtnLabel.implicitWidth + 18
                                implicitHeight: 28
                                radius: 6
                                color: pairHov.hovered ? Theme.accentGlow : Theme.accent

                                Text {
                                    id: pairBtnLabel
                                    anchors.centerIn: parent
                                    text: devDelegate.dev.pairing ? "Pairing" : "Pair"
                                    color: Theme.bgDark
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 11
                                    font.weight: Theme.fontWeightBold
                                }

                                HoverHandler { id: pairHov }
                                TapHandler {
                                    onTapped: devDelegate.dev.pair()
                                }
                            }
                        }

                        HoverHandler { id: devHover }
                        TapHandler {
                            onTapped: {
                                if (devDelegate.isPaired) {
                                    if (devDelegate.dev.connected) {
                                        devDelegate.dev.disconnect()
                                    } else {
                                        devDelegate.dev.connect()
                                    }
                                } else {
                                    devDelegate.dev.pair()
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.combinedList.length === 0
                        anchors.centerIn: parent
                        text: root.isDiscovering ? "Searching for nearby devices..." : "No devices found"
                        color: Theme.fgDim
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 13
                    }
                }

                // Subtle Bottom Toolbar Links (Matching Theme)
                RowLayout {
                    visible: root.adapter !== null && root.isPowered
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    spacing: 8

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰇮"
                            color: sendLnkHov.hovered ? Theme.accent : Theme.blue
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            text: "Send Files"
                            color: sendLnkHov.hovered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 11.5
                            font.weight: Theme.fontWeight
                        }
                        HoverHandler { id: sendLnkHov }
                        TapHandler { onTapped: root.sendFile(root.connectedDevice) }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 5
                        Text {
                            text: "󰒓"
                            color: mgrLnkHov.hovered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            text: "Settings"
                            color: mgrLnkHov.hovered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 11.5
                            font.weight: Theme.fontWeight
                        }
                        HoverHandler { id: mgrLnkHov }
                        TapHandler { onTapped: root.openManager() }
                    }
                }
            }
        }
    }
}
