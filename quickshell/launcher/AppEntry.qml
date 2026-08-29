import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Rectangle {
    id: root
    width: ListView.view.width
    height: 48
    radius: 8
    color: {
        if (ListView.isCurrentItem) return Theme.accent
        if (hover.hovered) return Theme.bgLight
        return "transparent"
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: launch() }

    function launch() {
        if (modelData && modelData.execute) {
            modelData.execute()
        }
        UiState.launcherVisible = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12
        
        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            
            IconImage {
                anchors.fill: parent
                source: modelData && modelData.icon ? Quickshell.iconPath(modelData.icon, "application-x-executable") : ""
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: (modelData && modelData.name) ? modelData.name : ""
                color: ListView.isCurrentItem ? Theme.bgDark : Theme.fg
                font.weight: Theme.fontWeight
                font.family: Theme.fontFamilySans
            }
            Text {
                text: (modelData && modelData.comment) ? modelData.comment : (modelData && modelData.genericName ? modelData.genericName : "")
                color: ListView.isCurrentItem ? Theme.bg : Theme.fgDim
                font.pixelSize: 12
                font.family: Theme.fontFamilySans
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
