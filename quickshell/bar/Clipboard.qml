import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    property string targetScreenName: ""
    
    active: UiState.clipboardVisible
    implicitWidth: Theme.compactPillSize
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            // "format": "<span color='#bb9af7'> {text} </span>"
            // "text": "󰅌"
            text: "󰅌"
            color: Theme.purple // #bb9af7
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            UiState.toggleClipboard(root.targetScreenName)
        }
    }
}
