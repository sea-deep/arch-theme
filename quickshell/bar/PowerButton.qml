import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    active: UiState.powerMenuVisible
    implicitWidth: Theme.compactPillSize
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            // "format": "  "
            text: ""
            color: Theme.red // CSS: #custom-power { color: #f7768e; }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            UiState.togglePower()
        }
    }
}
