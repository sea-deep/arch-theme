import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: root
    property var flatEmojis: []
    property string searchQuery: ""
    
    Component.onCompleted: {
        var arr = []
        for(var i=0; i<10; i++) arr.push({char: "😀", name: "smile"})
        flatEmojis = arr
    }

    width: 340; height: 440; visible: true
    ColumnLayout {
        anchors.fill: parent
        
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 36; color: "red" }
        
        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 39.5; cellHeight: 39.5
            model: root.searchQuery === "" ? root.flatEmojis : root.flatEmojis.filter(function(e) { return true })
            delegate: Text { text: modelData.char }
            Component.onCompleted: console.log("GridView height:", height)
        }
        
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "white" }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 32; color: "blue" }
    }
}
