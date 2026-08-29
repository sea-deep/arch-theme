import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    implicitWidth: layout.implicitWidth + Theme.pillPaddingHoriz * 2
    
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        // Use spaces inside the strings rather than layout spacing to exactly mimic the Waybar span gaps
        spacing: 0

        Text {
            text: "󰥔  "
            color: Theme.purple
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }

        Text {
            text: Qt.formatDateTime(clock.date, "h:mm AP") + "   "
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        
        Text {
            text: "󰃭  "
            color: Theme.blue
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        
        Text {
            text: Qt.formatDateTime(clock.date, "MMM d")
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }
}
