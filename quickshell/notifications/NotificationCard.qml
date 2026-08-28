import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../theme"

Rectangle {
    id: root
    width: parent.width
    height: content.height + 20
    color: Theme.bgLight
    radius: 10
    border.color: hover.hovered ? Theme.accentGlow : Theme.bgDark
    border.width: 1

    HoverHandler { id: hover }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Image {
                source: "image://icon/" + model.appIcon
                sourceSize: Qt.size(32, 32)
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: model.appName
                    color: Theme.fgDim
                    font.pixelSize: 12
                    font.family: Theme.fontFamilySans
                }
                Text {
                    text: model.summary
                    color: Theme.fg
                    font.bold: true
                    font.family: Theme.fontFamilySans
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            Text {
                text: model.timestamp
                color: Theme.fgMuted
                font.pixelSize: 10
                font.family: Theme.fontFamilySans
                Layout.alignment: Qt.AlignTop
            }
            Rectangle {
                width: 24; height: 24
                color: "transparent"
                visible: hover.hovered
                Layout.alignment: Qt.AlignTop
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: Theme.fg
                }
                TapHandler {
                    onTapped: NotificationServer.dismiss(index)
                }
            }
        }

        Text {
            text: model.body
            color: Theme.fgDim
            font.family: Theme.fontFamilySans
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            visible: text !== ""
        }
    }
}
