import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Rectangle {
    id: root
    required property var modelData
    width: parent ? parent.width : 300
    height: content.height + 20
    color: Theme.bgLight
    radius: Theme.radius - 2
    border.color: hover.hovered ? Theme.accentGlow : Theme.bgDark
    border.width: Theme.borderWidth

    HoverHandler { id: hover }

    TapHandler {
        onTapped: {
            // Try to find a default action and invoke it, otherwise dismiss
            if (root.modelData.actions) {
                for (let i = 0; i < root.modelData.actions.length; i++) {
                    if (root.modelData.actions[i].identifier === "default") {
                        if (typeof root.modelData.actions[i].invoke === "function") {
                            root.modelData.actions[i].invoke();
                            return;
                        }
                    }
                }
            }
            // Fallbacks if action objects don't have .invoke()
            if (typeof root.modelData.invoke === "function") {
                root.modelData.invoke("default");
            } else if (typeof root.modelData.invokeAction === "function") {
                root.modelData.invokeAction("default");
            } else {
                NotificationServer.dismiss(root.modelData);
            }
        }
    }

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
            IconImage {
                implicitWidth: 30
                implicitHeight: 30
                source: root.modelData.image !== ""
                    ? root.modelData.image
                    : Quickshell.iconPath(root.modelData.appIcon, "dialog-information")
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: root.modelData.appName
                    color: Theme.fgDim
                    font.pixelSize: 11
                    font.family: Theme.fontFamilySans
                }
                Text {
                    text: root.modelData.summary
                    color: Theme.fg
                    font.weight: Theme.fontWeight
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            Rectangle {
                width: 24; height: 24
                color: "transparent"
                Layout.alignment: Qt.AlignTop
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: Theme.fg
                }
                TapHandler {
                    onTapped: NotificationServer.dismiss(root.modelData)
                }
            }
        }

        Text {
            text: root.modelData.body
            textFormat: Text.StyledText
            color: Theme.fgDim
            font.family: Theme.fontFamilySans
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            maximumLineCount: 4
            elide: Text.ElideRight
            visible: text !== ""
            onLinkActivated: (link) => Qt.openUrlExternally(link)
            
            HoverHandler {
                cursorShape: Qt.IBeamCursor
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            visible: root.modelData.actions !== undefined && root.modelData.actions !== null && root.modelData.actions.length > 0
            
            Repeater {
                model: root.modelData.actions
                delegate: Rectangle {
                    // Hide default action button
                    visible: modelData.identifier !== "default"
                    width: visible ? implicitWidth : 0
                    height: visible ? implicitHeight : 0
                    
                    color: hoverAction.hovered ? Theme.surface : Theme.bgDark
                    border.color: Theme.bgLight
                    border.width: 1
                    radius: Theme.radius - 2
                    implicitWidth: actionText.implicitWidth + 24
                    implicitHeight: 28
                    
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text || modelData.identifier || ""
                        color: Theme.fg
                        font.pixelSize: 12
                    }
                    HoverHandler { id: hoverAction }
                    TapHandler { 
                        onTapped: {
                            if (typeof modelData.invoke === "function") {
                                modelData.invoke()
                            } else if (typeof root.modelData.invoke === "function") {
                                root.modelData.invoke(modelData.identifier)
                            } else if (typeof root.modelData.invokeAction === "function") {
                                root.modelData.invokeAction(modelData.identifier)
                            }
                        } 
                    }
                }
            }
        }
    }
}
