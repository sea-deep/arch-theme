import QtQuick
import QtQuick.Layouts

Window {
    width: 340; height: 440; visible: true
    ColumnLayout {
        anchors.fill: parent
        
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 36; color: "red" }
        
        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: 0
            Component.onCompleted: console.log("GridView visible:", visible, "height:", height)
        }
        
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 32; color: "blue" }
    }
}
