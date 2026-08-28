import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    collapseWhenEmpty: true
    isEmpty: !SystemTray.items || SystemTray.items.values.length === 0
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10
        
        Repeater {
            model: SystemTray.items
            
            Item {
                required property var modelData
                
                width: 18
                height: 18
                
                Image {
                    anchors.fill: parent
                    source: parent.modelData.icon ? (parent.modelData.icon.startsWith("/") ? ("file://" + parent.modelData.icon) : ("image://icon/" + parent.modelData.icon)) : ""
                    sourceSize: Qt.size(18, 18)
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            parent.modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            parent.modelData.secondaryActivate()
                        }
                    }
                }
            }
        }
    }
}
