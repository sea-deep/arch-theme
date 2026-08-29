import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Rectangle {
    id: root

    required property var notification
    readonly property int contentPadding: Theme.spacingMd
    width: parent ? parent.width : 300
    implicitHeight: content.implicitHeight + contentPadding * 2
    height: implicitHeight
    color: Theme.bgLight
    radius: Theme.radius - 2
    border.color: hover.hovered ? Theme.accentGlow : Theme.bgDark
    border.width: Theme.borderWidth
    
    // Safety check for null modelData
    visible: notification !== null

    HoverHandler { id: hover }

    TapHandler {
        onTapped: {
            if (!root.notification) return;
            if (root.notification.actions) {
                for (let i = 0; i < root.notification.actions.length; i++) {
                    if (root.notification.actions[i].identifier === "default") {
                        if (typeof root.notification.actions[i].invoke === "function") {
                            root.notification.actions[i].invoke();
                            return;
                        }
                    }
                }
            }
            if (typeof root.notification.invoke === "function") {
                root.notification.invoke("default");
            } else if (typeof root.notification.invokeAction === "function") {
                root.notification.invokeAction("default");
            } else {
                NotificationServer.dismiss(root.notification);
            }
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.contentPadding
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconImage {
                implicitWidth: 30
                implicitHeight: 30
                source: root.notification && !root.notification.lastGeneration
                    && root.notification.image !== ""
                    ? root.notification.image
                    : Quickshell.iconPath(root.notification ? root.notification.appIcon : "", "dialog-information")
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: root.notification ? root.notification.appName : ""
                    color: Theme.fgDim
                    font.pixelSize: 11
                    font.family: Theme.fontFamilySans
                }
                Text {
                    text: root.notification ? root.notification.summary : ""
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
                    onTapped: {
                        if (root.notification) NotificationServer.dismiss(root.notification)
                    }
                }
            }
        }

        Text {
            text: root.notification ? root.notification.body : ""
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
            visible: root.notification && root.notification.actions !== undefined && root.notification.actions !== null && root.notification.actions.length > 0
            
            Repeater {
                model: root.notification ? root.notification.actions : []
                delegate: Rectangle {
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
                            if (!root.notification) return;
                            if (typeof modelData.invoke === "function") {
                                modelData.invoke()
                            } else if (typeof root.notification.invoke === "function") {
                                root.notification.invoke(modelData.identifier)
                            } else if (typeof root.notification.invokeAction === "function") {
                                root.notification.invokeAction(modelData.identifier)
                            }
                        } 
                    }
                }
            }
        }
    }
}
