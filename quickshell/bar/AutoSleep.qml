import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    required property var hostWindow
    
    collapseWhenEmpty: true
    isEmpty: !UiState.caffeineEnabled
    
    implicitWidth: Theme.compactPillSize
    
    IdleInhibitor {
        window: root.hostWindow
        enabled: UiState.caffeineEnabled
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            text: "󰅶"
            color: Theme.yellow
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            visible: UiState.caffeineEnabled
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            UiState.caffeineEnabled = !UiState.caffeineEnabled
        }
    }
}
