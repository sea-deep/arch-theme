import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root
    width: ListView.view.width
    height: 48
    radius: 8
    color: {
        if (ListView.isCurrentItem) return Theme.Theme.accent
        if (hover.hovered) return Theme.Theme.bgLight
        return "transparent"
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: launch() }

    function launch() {
        if (modelData && modelData.execute) {
            modelData.execute()
        }
        root.parent.parent.parent.parent.isActive = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12
        
        Image {
            source: (modelData && modelData.icon) ? ("image://icon/" + modelData.icon) : ""
            sourceSize: Qt.size(32, 32)
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.maximumWidth: 32
            Layout.maximumHeight: 32
            fillMode: Image.PreserveAspectFit
            visible: source !== ""
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: (modelData && modelData.name) ? modelData.name : ""
                color: ListView.isCurrentItem ? Theme.Theme.bgDark : Theme.Theme.fg
                font.bold: true
                font.family: Theme.Theme.fontFamilySans
            }
            Text {
                text: (modelData && modelData.comment) ? modelData.comment : (modelData && modelData.genericName ? modelData.genericName : "")
                color: ListView.isCurrentItem ? Theme.Theme.bg : Theme.Theme.fgDim
                font.pixelSize: 12
                font.family: Theme.Theme.fontFamilySans
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
