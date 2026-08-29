import QtQuick
import QtQuick.Controls

Window {
    width: 300; height: 300; visible: true
    property var arr: []
    Component.onCompleted: {
        var a = []
        for (var i = 0; i < 5; i++) a.push({c: "😀"})
        arr = a
    }
    GridView {
        anchors.fill: parent
        cellWidth: 50; cellHeight: 50
        model: arr
        delegate: Text { text: modelData.c; font.pixelSize: 30 }
    }
}
