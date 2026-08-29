import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    width: 340
    height: 440
    visible: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "red"
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: width / 8
            cellHeight: cellWidth
            clip: true
            model: [{"char": "A"}]
            delegate: Rectangle {
                width: grid.cellWidth
                height: grid.cellHeight
                color: "green"
                Text { text: modelData.char }
            }
            Component.onCompleted: console.log("GridView width:", width, "height:", height)
        }
    }
}
