import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Quickshell 1.0
import Quickshell.Io 1.0
import Quickshell.Services.DesktopEntries 1.0
import "../theme"

PanelWindow {
    id: root
    anchors.centerIn: parent
    layer: Layer.Overlay
    width: Screen.width
    height: Screen.height
    color: Qt.rgba(26/255, 27/255, 38/255, 0.7) // bg with 0.7 alpha
    
    property bool isActive: false
    visible: isActive
    
    onIsActiveChanged: {
        if (isActive) {
            searchInput.forceActiveFocus()
            searchInput.text = ""
        }
    }

    TapHandler {
        onTapped: root.isActive = false
    }

    Rectangle {
        width: 500
        height: Math.min(600, appList.contentHeight + 80)
        anchors.centerIn: parent
        color: Theme.bg
        radius: 16
        border.color: Theme.accent
        border.width: 1

        TapHandler {
            // consume clicks on the card
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Theme.bgLight
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    Text {
                        text: "" // search icon
                        font.family: Theme.fontFamily
                        color: Theme.fgDim
                    }
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.fg
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 16
                        
                        Keys.onEscapePressed: root.isActive = false
                        Keys.onDownPressed: appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 1)
                        Keys.onUpPressed: appList.currentIndex = Math.max(0, appList.currentIndex - 1)
                        Keys.onReturnPressed: {
                            if (appList.currentItem) {
                                appList.currentItem.launch()
                            }
                        }
                    }
                }
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: DesktopEntries.applications.filter(function(app) {
                    var query = searchInput.text.toLowerCase();
                    if (query === "") return true;
                    return app.name.toLowerCase().includes(query) || 
                           (app.exec && app.exec.toLowerCase().includes(query)) ||
                           (app.keywords && app.keywords.join(" ").toLowerCase().includes(query));
                })
                
                delegate: AppEntry {}
            }
        }
    }
    
    Behavior on opacity { NumberAnimation { duration: 200 } }
    opacity: isActive ? 1.0 : 0.0
}
