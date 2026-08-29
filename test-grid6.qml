import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    width: 340; height: 440; visible: true
    property var arr: []
    Component.onCompleted: {
        var a = []
        for (var i = 0; i < 50; i++) a.push({char: "😀"})
        arr = a
    }
    GridView {
        anchors.fill: parent
        cellWidth: 39.5
        cellHeight: 39.5
        model: arr
        delegate: Text { text: modelData.char }
        onCountChanged: console.log("Count:", count, "contentHeight:", contentHeight)
    }
}
