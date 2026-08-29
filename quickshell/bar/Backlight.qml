import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

Item {
    id: root
    signal primaryClicked()
    implicitWidth: layout.implicitWidth + 16
    implicitHeight: Theme.barHeight

    readonly property int percentage: Brightness.percentage

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - 12)
        height: 2
        radius: 1
        color: Theme.yellow
        opacity: brightnessHover.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionMicro } }
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
            Brightness.adjust(wheel.angleDelta.y)
            wheel.accepted = true
        }
    }

    HoverHandler { id: brightnessHover }
}
