import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../theme"
import "../components" as Components
import "../bar" as BarModules

Components.Pill {
    id: root

    property string targetScreenName: ""
    readonly property bool expanded: UiState.quickControlVisible
        && (UiState.quickControlScreen === "" || UiState.quickControlScreen === targetScreenName)
    readonly property var audioStreams: Pipewire.nodes && Pipewire.nodes.values
        ? Pipewire.nodes.values.filter(node => node.isStream && node.audio !== null).slice(0, 3)
        : []
    readonly property var batteries: UPower.devices && UPower.devices.values
        ? UPower.devices.values.filter(device => device.isLaptopBattery && device.isPresent)
        : []
    readonly property int bodyHeight: UiState.quickControlMode === "audio"
        ? 128 + audioStreams.length * 52
        : (UiState.quickControlMode === "brightness" ? 188 : 158)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property int maxBrightness: parseInt(maxBrightnessFile.text()) || 100
    readonly property int currentBrightness: parseInt(brightnessFile.text()) || 0

    property real reveal: expanded ? 1 : 0
    property string tlpProfile: "unknown"

    implicitWidth: metricRow.implicitWidth + 12
    implicitHeight: Theme.barHeight + bodyHeight * reveal
    clip: true
    focus: expanded

    Behavior on implicitHeight {
        NumberAnimation { duration: 105; easing.type: Easing.OutQuart }
    }

    onExpandedChanged: {
        if (expanded) {
            Qt.callLater(() => root.forceActiveFocus())
            if (UiState.quickControlMode === "battery" && !tlpProfileProbe.running)
                tlpProfileProbe.running = true
        }
    }

    Keys.onEscapePressed: UiState.quickControlVisible = false

    PwObjectTracker { objects: [root.sink, root.source].concat(root.audioStreams) }

    FileView {
        id: maxBrightnessFile
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: brightnessFile
        path: "/sys/class/backlight/intel_backlight/brightness"
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: tlpProfileProbe
        command: ["/usr/bin/tlp-stat", "-s"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/TLP profile\s*=\s*([^\n]+)/)
                root.tlpProfile = match ? match[1].trim().split("/")[0].toLowerCase() : "unknown"
            }
        }
    }

    Process {
        id: tlpApplyProcess
        onExited: (exitCode, exitStatus) => {
            // Never claim success optimistically. Read the profile TLP actually
            // saved after pkexec succeeds, is cancelled, or fails.
            if (!tlpProfileProbe.running)
                tlpProfileProbe.running = true
        }
    }

    function applyTlpProfile(profile) {
        if (tlpApplyProcess.running)
            return

        // The bar owns a full-screen light-dismiss region while expanded.
        // Close it before pkexec so the Polkit agent can receive input.
        UiState.quickControlVisible = false
        tlpApplyProcess.command = ["/usr/bin/setsid", "-w", "/usr/bin/pkexec", "/usr/bin/tlp", profile]
        Qt.callLater(() => tlpApplyProcess.running = true)
    }

    function toggle(mode) {
        UiState.toggleQuickControl(mode, targetScreenName)
    }

    function devicePercentage(device) {
        return device ? Math.round(device.percentage * 100) : 0
    }

    function deviceIsCharging(device) {
        return device && (device.state === UPowerDeviceState.Charging
            || device.state === UPowerDeviceState.PendingCharge
            || device.state === UPowerDeviceState.FullyCharged)
    }

    function deviceBatteryIcon(device) {
        if (deviceIsCharging(device))
            return "󰂄"

        const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        return icons[Math.max(0, Math.min(10, Math.floor(devicePercentage(device) / 10)))]
    }

    component CleanSlider: Item {
        id: slider
        property real value: 0
        signal moved(real value)
        signal released(real value)
        implicitHeight: 26

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Theme.surface
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, slider.value))
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, slider.value * parent.width - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 15
            height: 15
            radius: 8
            color: Theme.fg
            border.width: Theme.borderWidth
            border.color: Theme.bgDark
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function updateValue(mouseX) {
                slider.moved(Math.max(0, Math.min(1, mouseX / width)))
            }
            onPressed: mouse => updateValue(mouse.x)
            onReleased: mouse => slider.released(Math.max(0, Math.min(1, mouse.x / width)))
            onPositionChanged: mouse => {
                if (pressed)
                    updateValue(mouse.x)
            }
            onWheel: wheel => slider.moved(Math.max(0, Math.min(1,
                slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    component AudioRow: RowLayout {
        id: audioRow
        required property var node
        property string label: ""
        property string icon: ""
        readonly property bool available: node !== null && node.audio !== null && node.ready
        spacing: 7

        Text {
            text: audioRow.icon
            color: Theme.blue
            font.family: Theme.fontFamily
            font.pixelSize: 15
            Layout.preferredWidth: 18
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: audioRow.label
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: audioRow.available ? Math.round(audioRow.node.audio.volume * 100) + "%" : "--%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
            CleanSlider {
                Layout.fillWidth: true
                value: audioRow.available ? Math.min(1, audioRow.node.audio.volume) : 0
                onMoved: value => {
                    if (audioRow.available)
                        audioRow.node.audio.volume = value
                }
            }
        }
        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 8
            color: audioRow.available && audioRow.node.audio.muted ? Theme.red : Theme.bgLight
            Text {
                anchors.centerIn: parent
                text: audioRow.available && audioRow.node.audio.muted ? "󰖁" : audioRow.icon
                color: audioRow.available && audioRow.node.audio.muted ? Theme.bgDark : Theme.blue
                font.family: Theme.fontFamily
            }
            HoverHandler { id: muteHover }
            TapHandler {
                onTapped: {
                    if (audioRow.available)
                        audioRow.node.audio.muted = !audioRow.node.audio.muted
                }
            }
        }
    }

    RowLayout {
        id: metricRow
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: Theme.barHeight
        spacing: 0

        BarModules.Audio { onPrimaryClicked: root.toggle("audio") }
        BarModules.Backlight { onPrimaryClicked: root.toggle("brightness") }
        BarModules.Battery { onPrimaryClicked: root.toggle("battery") }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight - 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.borderWidth
        anchors.rightMargin: Theme.borderWidth
        height: 1
        color: Theme.surface
        visible: root.reveal > 0
    }

    Item {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bodyHeight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6
            visible: UiState.quickControlMode === "audio"

            AudioRow { Layout.fillWidth: true; node: root.sink; label: "Output"; icon: "󰕾" }
            AudioRow { Layout.fillWidth: true; node: root.source; label: "Microphone"; icon: "󰍬" }
            Repeater {
                model: root.audioStreams
                AudioRow {
                    required property var modelData
                    Layout.fillWidth: true
                    node: modelData
                    label: modelData.description || modelData.nickname || modelData.name || "Application"
                    icon: "󰎈"
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 7
            visible: UiState.quickControlMode === "brightness"

            RowLayout {
                Layout.fillWidth: true
                Text { text: "󰖔"; color: Theme.yellow; font.family: Theme.fontFamily; font.pixelSize: 16 }
                CleanSlider {
                    Layout.fillWidth: true
                    value: UiState.comfortValue / 100.0
                    onMoved: value => { UiState.comfortValue = value * 100 }
                }
                Text {
                    text: Math.round(UiState.comfortValue) + "%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "󰈈"; color: Theme.fgDim; font.family: Theme.fontFamily; font.pixelSize: 16 }
                CleanSlider {
                    Layout.fillWidth: true
                    value: UiState.grayscaleValue / 100.0
                    onMoved: value => { UiState.grayscaleValue = value * 100 }
                }
                Text {
                    text: Math.round(UiState.grayscaleValue) + "%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "󰸌"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: 16 }
                CleanSlider {
                    Layout.fillWidth: true
                    value: UiState.vividValue / 100.0
                    onMoved: value => { UiState.vividValue = value * 100 }
                }
                Text {
                    text: Math.round(UiState.vividValue) + "%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "󰃠"; color: Theme.yellow; font.family: Theme.fontFamily; font.pixelSize: 16 }
                CleanSlider {
                    Layout.fillWidth: true
                    value: root.currentBrightness / root.maxBrightness
                    onMoved: value => Quickshell.execDetached([
                        "brightnessctl", "set", Math.max(1, Math.round(value * 100)) + "%"
                    ])
                }
                Text {
                    text: Math.round((root.currentBrightness / root.maxBrightness) * 100) + "%"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 8
                color: UiState.caffeineEnabled ? Theme.yellow : Theme.bgLight
                Text {
                    anchors.centerIn: parent
                    text: UiState.caffeineEnabled ? "󰅶  Caffeine on" : "󰾪  Caffeine off"
                    color: UiState.caffeineEnabled ? Theme.bgDark : Theme.fg
                    font.family: Theme.fontFamily
                    font.weight: Theme.fontWeight
                }
                HoverHandler { id: caffeineHover }
                TapHandler { onTapped: UiState.caffeineEnabled = !UiState.caffeineEnabled }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6
            visible: UiState.quickControlMode === "battery"

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: root.batteries
                    Rectangle {
                        id: batteryCard
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 8
                        color: Theme.bgLight
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6
                            Text {
                                Layout.preferredWidth: 18
                                horizontalAlignment: Text.AlignHCenter
                                text: root.deviceBatteryIcon(batteryCard.modelData)
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                            Text {
                                text: batteryCard.modelData.nativePath
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Theme.fontWeight
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: root.devicePercentage(batteryCard.modelData) + "%"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Theme.fontWeight
                            }
                        }
                    }
                }
            }

            Repeater {
                model: [
                    { name: "Performance", profile: "performance", icon: "󰓅" },
                    { name: "Balanced", profile: "balanced", icon: "󰾅" },
                    { name: "Power saver", profile: "power-saver", icon: "󰌪" }
                ]
                Rectangle {
                    id: profileButton
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 8
                    color: root.tlpProfile === modelData.profile
                        ? Theme.accent : (profileHover.hovered ? Theme.surface : Theme.bgLight)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                            text: profileButton.modelData.icon
                            color: root.tlpProfile === profileButton.modelData.profile
                                ? Theme.bgDark : Theme.blue
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            text: profileButton.modelData.name
                            color: root.tlpProfile === profileButton.modelData.profile
                                ? Theme.bgDark : Theme.fg
                            font.family: Theme.fontFamily
                            font.weight: Theme.fontWeight
                        }
                    }
                    HoverHandler { id: profileHover }
                    TapHandler {
                        onTapped: root.applyTlpProfile(profileButton.modelData.profile)
                    }
                }
            }
        }
    }
}
