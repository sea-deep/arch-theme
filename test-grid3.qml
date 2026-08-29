import QtQuick
import QtQuick.Layouts

Window {
    width: 340; height: 440; visible: true
    ColumnLayout {
        anchors.fill: parent
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "red"
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "green"
            Component.onCompleted: console.log("Green height with 'height:36' sibling:", height)
        }
    }
}
