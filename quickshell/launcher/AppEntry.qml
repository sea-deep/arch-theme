import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell.Io 1.0
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
        execProcess.command = ["sh", "-c", modelData.exec]
        execProcess.running = true
        root.parent.parent.parent.parent.isActive = false // close launcher
    }

    Process {
        id: execProcess
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12
        
        Image {
            source: "image://icon/" + modelData.iconName
            sourceSize: Qt.size(32, 32)
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: modelData.name
                color: ListView.isCurrentItem ? Theme.bgDark : Theme.fg
                font.bold: true
                font.family: Theme.fontFamilySans
            }
            Text {
                text: modelData.description || ""
                color: ListView.isCurrentItem ? Theme.bg : Theme.fgDim
                font.pixelSize: 12
                font.family: Theme.fontFamilySans
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
