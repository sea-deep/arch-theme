import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme" as Theme

PanelWindow {
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    color: Qt.rgba(26/255, 27/255, 38/255, 0.7)
    
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
        color: Theme.Theme.bg
        radius: 16
        border.color: Theme.Theme.accent
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
                color: Theme.Theme.bgLight
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    Text {
                        text: ""
                        font.family: Theme.Theme.fontFamily
                        color: Theme.Theme.fgDim
                    }
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.Theme.fg
                        font.family: Theme.Theme.fontFamilySans
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
                model: DesktopEntries.applications.values.filter(function(app) {
                    var query = searchInput.text.toLowerCase();
                    if (query === "") return !app.noDisplay;
                    return !app.noDisplay && (
                        (app.name && app.name.toLowerCase().includes(query)) || 
                        (app.comment && app.comment.toLowerCase().includes(query)) ||
                        (app.genericName && app.genericName.toLowerCase().includes(query))
                    );
                })
                
                delegate: AppEntry {}
            }
        }
    }
    
}
