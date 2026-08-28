import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    property string timeString: ""
    property string dateString: ""
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date()
            root.timeString = d.toLocaleTimeString(Qt.locale(), "hh:mm AP")
            root.dateString = d.toLocaleDateString(Qt.locale(), "ddd dd")
        }
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing * 2
        
        RowLayout {
            spacing: Theme.spacing
            Text {
                text: "󰥔"
                color: Theme.purple
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
            }
            Text {
                text: root.timeString
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }
        
        RowLayout {
            spacing: Theme.spacing
            Text {
                text: "󰃭"
                color: Theme.blue
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
            }
            Text {
                text: root.dateString
                color: Theme.fg
                font.family: Theme.fontFamilySans
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }
    }
}
