import QtQuick
import QtQuick.Layouts

Window {
    width: 340; height: 440; visible: true
    ColumnLayout {
        anchors.fill: parent
        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: width / 8
            cellHeight: cellWidth
            model: 100
            delegate: Rectangle { color: "blue"; width: 20; height: 20; border.color: "white" }
        }
    }
}
