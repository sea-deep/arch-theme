import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
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

    readonly property int bodyHeight: !isPowered ? 160 : 420
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
        if (!device) {
            Quickshell.execDetached(["blueman-sendto"])
        } else {
            const addr = device.address || ""
            if (addr !== "") {
                Quickshell.execDetached(["blueman-sendto", "--device=" + addr])
            } else {
                Quickshell.execDetached(["blueman-sendto"])
            }
        }
    }

    function openManager() {
        Quickshell.execDetached(["blueman-manager"])
    }

    function getDeviceIcon(device) {
        if (!device) return "󰂯"
        const icon = (device.icon || "").toLowerCase()
        const name = (device.name || device.deviceName || "").toLowerCase()
        
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

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Text {
                            text: "󰂯"
                            color: Theme.blue
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Bluetooth"
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 15
                            font.weight: Theme.fontWeightBold
                            elide: Text.ElideRight
                        }
                    }

                    // Power Switch
                    RowLayout {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 26
                        spacing: 6

                        Text {
                            text: root.isPowered ? "On" : "Off"
                            color: root.isPowered ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                        }

                        Rectangle {
                            id: powerSwitch
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 18
                            radius: 9
                            color: root.isPowered ? Theme.accent : Theme.surface

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
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

                // Main Controls & Device Lists when powered on
                ColumnLayout {
                    visible: root.adapter !== null && root.isPowered
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    // Quick Action Buttons (Scan/Pair + Send Files + Manager)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        spacing: 6

                        // Scan / Pair Toggle Button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.radiusSmall
                            color: root.isDiscovering 
                                ? Theme.accent 
                                : (scanBtnHover.hovered ? Theme.surface : Theme.bgLight)

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰑐"
                                    color: root.isDiscovering ? Theme.bgDark : Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14

                                    RotationAnimation on rotation {
                                        running: root.isDiscovering
                                        from: 0; to: 360
                                        duration: 1000
                                        loops: Animation.Infinite
                                    }
                                }

                                Text {
                                    text: root.isDiscovering ? "Scanning..." : "Pair New Device"
                                    color: root.isDiscovering ? Theme.bgDark : Theme.fg
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 11
                                    font.weight: Theme.fontWeightBold
                                }
                            }

                            HoverHandler { id: scanBtnHover }
                            TapHandler {
                                onTapped: {
                                    if (root.adapter) {
                                        root.adapter.discovering = !root.adapter.discovering
                                    }
                                }
                            }
                        }

                        // Send Files Button
                        Rectangle {
                            Layout.preferredWidth: sendRow.implicitWidth + 16
                            Layout.fillHeight: true
                            radius: Theme.radiusSmall
                            color: sendBtnHover.hovered ? Theme.surface : Theme.bgLight

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                            RowLayout {
                                id: sendRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: "󰇮"
                                    color: Theme.blue
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                }

                                Text {
                                    text: "Send Files"
                                    color: Theme.fg
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 11
                                    font.weight: Theme.fontWeight
                                }
                            }

                            HoverHandler { id: sendBtnHover }
                            TapHandler {
                                onTapped: root.sendFile(root.connectedDevice)
                            }
                        }

                        // Open Manager Button
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.fillHeight: true
                            radius: Theme.radiusSmall
                            color: mgrBtnHover.hovered ? Theme.surface : Theme.bgLight

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰒓"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }

                            HoverHandler { id: mgrBtnHover }
                            TapHandler {
                                onTapped: root.openManager()
                            }
                        }
                    }

                    // Scrollable List of Paired & Available Devices
                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent ? parent.width : 340
                            spacing: 8

                            // Section 1: Paired Devices Header
                            Text {
                                visible: root.pairedDevices.length > 0
                                text: "PAIRED DEVICES"
                                color: Theme.fgDim
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 11
                                font.weight: Theme.fontWeightBold
                                Layout.leftMargin: 2
                            }

                            Repeater {
                                model: root.pairedDevices

                                Rectangle {
                                    id: pairedDelegate
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    radius: Theme.radiusSmall
                                    color: modelData.connected ? Theme.accent
                                        : (devHover.hovered ? Theme.surface : Theme.bgLight)
                                    border.width: 0

                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Text {
                                            text: root.getDeviceIcon(pairedDelegate.modelData)
                                            color: pairedDelegate.modelData.connected ? Theme.bgDark : Theme.blue
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 22
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                Layout.fillWidth: true
                                                text: pairedDelegate.modelData.name || pairedDelegate.modelData.deviceName || pairedDelegate.modelData.address
                                                color: pairedDelegate.modelData.connected ? Theme.bgDark : Theme.fg
                                                elide: Text.ElideRight
                                                font.family: Theme.fontFamilySans
                                                font.pixelSize: 13
                                                font.weight: Theme.fontWeight
                                            }

                                            RowLayout {
                                                spacing: 6
                                                Text {
                                                    text: pairedDelegate.modelData.connected ? "Connected" : (pairedDelegate.modelData.state === BluetoothDeviceState.Connecting ? "Connecting..." : "Paired")
                                                    color: pairedDelegate.modelData.connected ? Theme.bgDark : Theme.fgDim
                                                    font.family: Theme.fontFamilySans
                                                    font.pixelSize: 11
                                                }

                                                Text {
                                                    visible: pairedDelegate.modelData.batteryAvailable
                                                    text: "· 󰁹 " + Math.round(pairedDelegate.modelData.battery * 100) + "%"
                                                    color: pairedDelegate.modelData.connected ? Theme.bgDark : Theme.fgDim
                                                    font.family: Theme.fontFamilySans
                                                    font.pixelSize: 11
                                                }
                                            }
                                        }

                                        // Send File quick action button
                                        Rectangle {
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            radius: 6
                                            color: sendFileHover.hovered 
                                                ? (pairedDelegate.modelData.connected ? Qt.rgba(0, 0, 0, 0.25) : Theme.surfaceVariant)
                                                : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰇮"
                                                color: pairedDelegate.modelData.connected ? Theme.bgDark : Theme.blue
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 13
                                            }

                                            HoverHandler { id: sendFileHover }
                                            TapHandler {
                                                onTapped: root.sendFile(pairedDelegate.modelData)
                                            }
                                        }

                                        // Forget / Unpair button
                                        Rectangle {
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            radius: 6
                                            color: forgetHover.hovered 
                                                ? (pairedDelegate.modelData.connected ? Qt.rgba(0, 0, 0, 0.25) : Theme.surfaceVariant)
                                                : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰆴"
                                                color: pairedDelegate.modelData.connected ? Theme.bgDark : Theme.fgDim
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 13
                                            }

                                            HoverHandler { id: forgetHover }
                                            TapHandler {
                                                onTapped: pairedDelegate.modelData.forget()
                                            }
                                        }

                                        // Connect / Disconnect Action Icon Button
                                        Rectangle {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            radius: 6
                                            color: actionHover.hovered 
                                                ? (pairedDelegate.modelData.connected ? Qt.rgba(0, 0, 0, 0.25) : Theme.surfaceVariant)
                                                : (pairedDelegate.modelData.connected ? Qt.rgba(0, 0, 0, 0.12) : Theme.surface)

                                            Text {
                                                anchors.centerIn: parent
                                                text: pairedDelegate.modelData.connected ? "󰅖" : "󰄬"
                                                color: pairedDelegate.modelData.connected ? Theme.bgDark : Theme.accent
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 14
                                            }

                                            HoverHandler { id: actionHover }
                                            TapHandler {
                                                onTapped: {
                                                    if (pairedDelegate.modelData.connected) {
                                                        pairedDelegate.modelData.disconnect()
                                                    } else {
                                                        pairedDelegate.modelData.connect()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    HoverHandler { id: devHover }
                                    TapHandler {
                                        onTapped: {
                                            if (pairedDelegate.modelData.connected) {
                                                pairedDelegate.modelData.disconnect()
                                            } else {
                                                pairedDelegate.modelData.connect()
                                            }
                                        }
                                    }
                                }
                            }

                            // Section 2: Available / Discovered Devices Header
                            RowLayout {
                                visible: root.availableDevices.length > 0 || root.isDiscovering
                                Layout.fillWidth: true
                                Layout.topMargin: 4

                                Text {
                                    text: "AVAILABLE DEVICES"
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 11
                                    font.weight: Theme.fontWeightBold
                                    Layout.leftMargin: 2
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    visible: root.isDiscovering
                                    text: "Searching..."
                                    color: Theme.accent
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 10
                                }
                            }

                            Repeater {
                                model: root.availableDevices

                                Rectangle {
                                    id: availDelegate
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: Theme.radiusSmall
                                    color: availHover.hovered ? Theme.surface : Theme.bgLight
                                    border.width: 0

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Text {
                                            text: root.getDeviceIcon(availDelegate.modelData)
                                            color: Theme.fgDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 18
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            Text {
                                                Layout.fillWidth: true
                                                text: availDelegate.modelData.name || availDelegate.modelData.deviceName || availDelegate.modelData.address
                                                color: Theme.fg
                                                elide: Text.ElideRight
                                                font.family: Theme.fontFamilySans
                                                font.pixelSize: 13
                                                font.weight: Theme.fontWeight
                                            }

                                            Text {
                                                text: availDelegate.modelData.pairing ? "Pairing..." : (availDelegate.modelData.address || "Ready to pair")
                                                color: Theme.fgDim
                                                font.family: Theme.fontFamilySans
                                                font.pixelSize: 10
                                            }
                                        }

                                        Rectangle {
                                            implicitWidth: pairBtnText.implicitWidth + 18
                                            implicitHeight: 28
                                            radius: 6
                                            color: pairBtnHover.hovered ? Theme.accentGlow : Theme.accent

                                            Text {
                                                id: pairBtnText
                                                anchors.centerIn: parent
                                                text: availDelegate.modelData.pairing ? "Pairing" : "Pair"
                                                color: Theme.bgDark
                                                font.family: Theme.fontFamilySans
                                                font.pixelSize: 11
                                                font.weight: Theme.fontWeightBold
                                            }

                                            HoverHandler { id: pairBtnHover }
                                            TapHandler {
                                                onTapped: availDelegate.modelData.pair()
                                            }
                                        }
                                    }

                                    HoverHandler { id: availHover }
                                    TapHandler {
                                        onTapped: availDelegate.modelData.pair()
                                    }
                                }
                            }

                            // Empty devices state when discovering but none found yet
                            Text {
                                visible: root.isDiscovering && root.availableDevices.length === 0
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 12
                                text: "Searching for nearby devices..."
                                color: Theme.fgDim
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
}
