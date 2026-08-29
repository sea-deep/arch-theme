import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../theme"

Item {
    id: root
    signal primaryClicked()

    implicitWidth: layout.implicitWidth + 16
    implicitHeight: Theme.barHeight

    readonly property var battery: UPower.displayDevice
    readonly property bool available: battery !== null && battery.ready && battery.isPresent
    readonly property int percentage: available ? Math.round(battery.percentage * 100) : 0
    readonly property bool isCharging: available && (
        battery.state === UPowerDeviceState.Charging
        || battery.state === UPowerDeviceState.PendingCharge
        || battery.state === UPowerDeviceState.FullyCharged)
    readonly property bool isCritical: available && percentage <= 10 && !isCharging

    function batteryIcon() {
        if (isCharging)
            return "󰂄"

        const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        return icons[Math.max(0, Math.min(10, Math.floor(percentage / 10)))]
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - 12)
        height: 2
        radius: 1
        color: Theme.accent
        opacity: batteryHover.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            text: root.batteryIcon()
            color: root.isCritical ? (blinkTimer.blinkState ? Theme.red : Theme.bgDark) : Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        Text {
            text: root.available ? root.percentage + "%" : "--%"
            color: root.isCritical ? (blinkTimer.blinkState ? Theme.red : Theme.bgDark) : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }

    Timer {
        id: blinkTimer
        interval: 500
        running: root.isCritical
        repeat: true
        property bool blinkState: false
        onTriggered: blinkState = !blinkState
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.primaryClicked()
    }

    HoverHandler { id: batteryHover }
}
