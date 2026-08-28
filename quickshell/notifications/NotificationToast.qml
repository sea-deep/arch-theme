import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell 1.0
import "../theme"

PanelWindow {
    id: root
    width: 350
    height: content.height + 20
    
    anchors.top: true
    anchors.right: true
    anchors.topMargin: 20
    anchors.rightMargin: 20
    
    layer: Layer.Overlay
    
    property bool isActive: false
    visible: isActive
    
    onIsActiveChanged: {
        if (isActive) {
            slideIn.start()
            autoDismiss.restart()
        }
    }
    
    NumberAnimation on x {
        id: slideIn
        from: Screen.width
        to: Screen.width - width - 20
        duration: 300
        easing.type: Easing.OutCubic
    }
    
    Timer {
        id: autoDismiss
        interval: 5000
        onTriggered: root.isActive = false
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.bgLight
        radius: Theme.radius
        border.color: hover.hovered ? Theme.accent : "transparent"
        border.width: 1

        HoverHandler { id: hover }
        TapHandler { onTapped: root.isActive = false }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8
            
            RowLayout {
                spacing: 8
                Image {
                    source: "image://icon/" + (modelData ? modelData.appIcon : "bell")
                    sourceSize: Qt.size(24, 24)
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: "Notification"
                    font.family: Theme.fontFamilySans
                    font.bold: true
                    color: Theme.fg
                    Layout.fillWidth: true
                }
            }
            
            Text {
                text: "Body"
                font.family: Theme.fontFamilySans
                color: Theme.fgDim
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
