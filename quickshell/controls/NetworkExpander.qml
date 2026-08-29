import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../theme"
import "../components" as Components

Item {
    id: root

    property string targetScreenName: ""
    property var pendingNetwork: null
    property string password: ""
    property string statusMessage: ""
    readonly property bool expanded: UiState.networkVisible
        && (UiState.networkScreen === "" || UiState.networkScreen === targetScreenName)
    readonly property var wifiDevice: {
        const devices = Networking.devices && Networking.devices.values
            ? Networking.devices.values : []
        return devices.find(device => device.type === DeviceType.Wifi) || null
    }
    readonly property var networks: {
        if (!wifiDevice || !wifiDevice.networks || !wifiDevice.networks.values)
            return []

        return wifiDevice.networks.values.slice().sort((left, right) => {
            if (left.connected !== right.connected)
                return left.connected ? -1 : 1
            if (left.known !== right.known)
                return left.known ? -1 : 1
            return right.signalStrength - left.signalStrength
        })
    }
    readonly property int bodyHeight: pendingNetwork ? 420 : 352
    property real reveal: expanded ? 1 : 0

    property real expandedWidth: 350
    implicitWidth: expanded || reveal > 0 ? expandedWidth : Theme.compactPillSize
    implicitHeight: reveal > 0
        ? Theme.barHeight + Theme.outerGap + bodyHeight * reveal
        : Theme.barHeight
    focus: expanded

    Behavior on reveal {
        NumberAnimation { duration: 110; easing.type: Easing.OutQuart }
    }

    onExpandedChanged: {
        if (expanded) {
            if (wifiDevice)
                wifiDevice.scannerEnabled = true
            Qt.callLater(() => root.forceActiveFocus())
        } else {
            if (wifiDevice)
                wifiDevice.scannerEnabled = false
            pendingNetwork = null
            password = ""
            statusMessage = ""
        }
    }

    Connections {
        target: root.wifiDevice
        function onScannerEnabledChanged() {
            if (root.expanded && !root.wifiDevice.scannerEnabled)
                root.wifiDevice.scannerEnabled = true
        }
    }

    function close() {
        UiState.networkVisible = false
    }

    function toggle() {
        UiState.toggleNetwork(targetScreenName)
    }

    function strengthIcon(network) {
        const value = Math.round((network ? network.signalStrength : 0) * 100)
        if (value <= 0) return "󰤯"
        if (value < 25) return "󰤟"
        if (value < 50) return "󰤢"
        if (value < 75) return "󰤥"
        return "󰤨"
    }

    function networkIcon() {
        if (!Networking.wifiHardwareEnabled || !Networking.wifiEnabled)
            return "󰤭"
        const connected = networks.find(network => network.connected)
        return connected ? strengthIcon(connected) : "󰤨"
    }

    function networkSummary() {
        if (!Networking.wifiHardwareEnabled)
            return "Wi-Fi hardware disabled"
        if (!Networking.wifiEnabled)
            return "Wi-Fi disabled"
        const connected = networks.find(network => network.connected)
        if (connected)
            return connected.name + " · " + Math.round(connected.signalStrength * 100) + "%"
        return "Not connected"
    }

    function requiresPassword(network) {
        return network && !network.known
            && network.security !== WifiSecurityType.Open
            && network.security !== WifiSecurityType.Owe
    }

    function activateNetwork(network) {
        if (!network || network.stateChanging)
            return

        if (network.connected) {
            network.disconnect()
            return
        }

        if (requiresPassword(network)) {
            pendingNetwork = network
            password = ""
            statusMessage = "Password required for " + network.name
            Qt.callLater(() => passwordInput.forceActiveFocus())
            return
        }

        network.connect()
        statusMessage = "Connecting to " + network.name
    }

    function connectWithPassword() {
        if (!pendingNetwork || password.length === 0)
            return

        pendingNetwork.connectWithPsk(password)
        statusMessage = "Connecting to " + pendingNetwork.name
        pendingNetwork = null
        password = ""
    }

    function handleEscape() {
        if (pendingNetwork) {
            pendingNetwork = null
            password = ""
            statusMessage = ""
        } else {
            close()
        }
    }

    Keys.onEscapePressed: root.handleEscape()

    Components.ConnectedDropdownSurface {
        anchors.fill: parent
        tabOnLeft: true
        tabWidth: Theme.compactPillSize
        visible: root.reveal > 0
    }

    Components.Pill {
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight
        visible: root.reveal <= 0
    }

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight

        Text {
            anchors.centerIn: parent
            text: root.networkIcon()
            color: Networking.wifiEnabled ? Theme.fg : Theme.fgMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Networking.wifiEnabled = !Networking.wifiEnabled
                else
                    root.toggle()
            }
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bodyHeight * root.reveal
        visible: height > 0
        color: "transparent"
        border.width: 0
        clip: true

        Item {
            anchors.top: parent.top
            width: parent.width
            height: root.bodyHeight

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 7

                    Text {
                        text: root.networkIcon()
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Network"
                        color: Theme.fg
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 14
                        font.weight: Theme.fontWeight
                    }
                    RowLayout {
                        Layout.preferredWidth: 62
                        Layout.preferredHeight: 26
                        Text {
                            text: "Wi-Fi"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Theme.fontWeight
                        }
                        Rectangle {
                            id: wifiSwitch
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 18
                            radius: height / 2
                            color: Networking.wifiEnabled ? Theme.accent : Theme.surface

                            Rectangle {
                                width: 14
                                height: 14
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                                color: Networking.wifiEnabled ? Theme.bgDark : Theme.fgDim

                                Behavior on x {
                                    NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                                }
                            }

                            HoverHandler { id: wifiToggleHover }
                            TapHandler { onTapped: Networking.wifiEnabled = !Networking.wifiEnabled }
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.surface
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Text {
                        Layout.fillWidth: true
                        text: root.statusMessage
                        color: Theme.accent
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                    Text {
                        text: root.wifiDevice && root.wifiDevice.scannerEnabled ? "󰑐 Scanning" : "󰑐 Refresh"
                        color: scanHover.hovered ? Theme.accent : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        HoverHandler { id: scanHover }
                        TapHandler {
                            onTapped: {
                                if (root.wifiDevice) {
                                    root.wifiDevice.scannerEnabled = false
                                    Qt.callLater(() => root.wifiDevice.scannerEnabled = true)
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: networkList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 80
                    model: root.networks
                    clip: true
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: networkDelegate
                        required property var modelData
                        width: ListView.view.width
                        height: 48
                        radius: 8
                        color: modelData.connected ? Theme.accent
                            : (networkHover.hovered ? Theme.surface : Theme.bgLight)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 8

                            Text {
                                text: root.strengthIcon(networkDelegate.modelData)
                                color: networkDelegate.modelData.connected ? Theme.bgDark : Theme.blue
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: networkDelegate.modelData.name || "Hidden network"
                                    color: networkDelegate.modelData.connected ? Theme.bgDark : Theme.fg
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Theme.fontWeight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: (networkDelegate.modelData.connected ? "Connected" :
                                        (networkDelegate.modelData.known ? "Saved" : "Available"))
                                        + " · " + Math.round(networkDelegate.modelData.signalStrength * 100) + "%"
                                    color: networkDelegate.modelData.connected ? Theme.bgDark : Theme.fgDim
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                            }
                            Text {
                                text: networkDelegate.modelData.stateChanging ? "󰔟"
                                    : (root.requiresPassword(networkDelegate.modelData) ? "󰌾" : "")
                                color: networkDelegate.modelData.connected ? Theme.bgDark : Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                        }

                        HoverHandler { id: networkHover }
                        TapHandler { onTapped: root.activateNetwork(networkDelegate.modelData) }
                        Connections {
                            target: networkDelegate.modelData
                            function onConnectionFailed(reason) {
                                if (reason === ConnectionFailReason.NoSecrets) {
                                    root.pendingNetwork = networkDelegate.modelData
                                    root.password = ""
                                    root.statusMessage = "Password required for " + networkDelegate.modelData.name
                                    Qt.callLater(() => passwordInput.forceActiveFocus())
                                } else {
                                    root.statusMessage = ConnectionFailReason.toString(reason)
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: networkList.count === 0
                        text: Networking.wifiEnabled ? "Scanning for networks…" : "Wi-Fi is off"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    visible: root.pendingNetwork !== null
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 66 : 0
                    radius: 8
                    color: Theme.bgLight

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 7
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: root.pendingNetwork ? "Password · " + root.pendingNetwork.name : ""
                                color: Theme.fg
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                            TextInput {
                                id: passwordInput
                                Layout.fillWidth: true
                                color: Theme.fg
                                selectionColor: Theme.accent
                                selectedTextColor: Theme.bgDark
                                echoMode: TextInput.Password
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                clip: true
                                text: root.password
                                onTextChanged: root.password = text
                                Keys.onReturnPressed: root.connectWithPassword()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !parent.text && !parent.activeFocus
                                    text: "Enter Wi-Fi password"
                                    color: Theme.fgMuted
                                    font: parent.font
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 54
                            Layout.preferredHeight: 28
                            radius: 8
                            color: connectHover.hovered ? Theme.accentGlow : Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Connect"
                                color: Theme.bgDark
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Theme.fontWeight
                            }
                            HoverHandler { id: connectHover }
                            TapHandler { onTapped: root.connectWithPassword() }
                        }
                    }
                }
            }
        }
    }
}
