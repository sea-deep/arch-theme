import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    color: Qt.rgba(26/255, 27/255, 38/255, 0.7)
    
    visible: UiState.launcherVisible

    onVisibleChanged: {
        if (visible) {
            searchInput.forceActiveFocus()
            searchInput.text = ""
        }
    }

    TapHandler {
        onTapped: UiState.launcherVisible = false
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
                        text: ""
                        font.family: Theme.fontFamily
                        color: Theme.fgDim
                    }
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.fg
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 16
                        
                        Keys.onEscapePressed: UiState.launcherVisible = false
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
