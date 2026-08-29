import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    width: 340; height: 440; visible: true
    ColumnLayout {
        anchors.fill: parent
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: width / 8
            cellHeight: cellWidth
            model: 100
            delegate: Rectangle {
                width: grid.cellWidth
                height: grid.cellHeight
                color: "green"
                border.color: "black"
                Text { text: "X"; anchors.centerIn: parent }
                Component.onCompleted: console.log("Delegate size:", width, height)
            }
        }
    }
}
