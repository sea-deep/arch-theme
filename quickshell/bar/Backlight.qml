import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root
    signal primaryClicked()
    implicitWidth: layout.implicitWidth + 16
    implicitHeight: Theme.barHeight

    // We bind to the max_brightness and brightness files directly to compute percentage
    FileView {
        id: maxBright
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        watchChanges: true
        onFileChanged: reload()
    }
    
    FileView {
        id: currBright
        path: "/sys/class/backlight/intel_backlight/brightness"
        watchChanges: true
        onFileChanged: reload()
    }
    
    property int maxB: parseInt(maxBright.text()) || 100
    property int currB: parseInt(currBright.text()) || 0
    property int percentage: Math.round((currB / maxB) * 100) || 0

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - 12)
        height: 2
        radius: 1
        color: Theme.yellow
        opacity: brightnessHover.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }

    function getIcon() {
        if (percentage < 33) return "󰃞"
        if (percentage < 66) return "󰃟"
        return "󰃠"
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            text: root.getIcon()
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        
        Text {
            text: root.percentage + "%"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.primaryClicked()
            } else if (mouse.button === Qt.MiddleButton) {
                UiState.caffeineEnabled = !UiState.caffeineEnabled
            }
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                Quickshell.execDetached(["brightnessctl", "set", "1%+"])
            } else {
                Quickshell.execDetached(["brightnessctl", "set", "1%-"])
            }
        }
    }

    HoverHandler { id: brightnessHover }
}
