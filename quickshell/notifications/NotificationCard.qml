import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Item {
    id: root
    property var notification: null
    property bool slidable: true
    signal dismissed()

    implicitWidth: 350
    implicitHeight: cardContainer.implicitHeight
    height: implicitHeight
    clip: false

    visible: notification !== null && opacity > 0

    property real slideOffset: 0
    readonly property bool isSwiping: dragArea.drag.active

    Behavior on slideOffset {
        enabled: !dragArea.drag.active
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: dismissAnim
        NumberAnimation {
            target: cardContainer
            property: "x"
            to: root.slideOffset < 0 ? -root.width - 40 : root.width + 40
            duration: 180
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 180
            easing.type: Easing.OutQuad
        }
        onFinished: {
            if (root.notification) {
                NotificationServer.dismiss(root.notification)
            }
            root.dismissed()
        }
    }

    Rectangle {
        id: cardContainer
        anchors.left: parent.left
        anchors.right: parent.right
        x: root.slideOffset
        implicitHeight: content.implicitHeight + 18
        height: implicitHeight
        color: hover.hovered ? Theme.surface : Theme.bgLight
        radius: Theme.radiusSmall
        border.width: 0

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        opacity: Math.max(0.0, 1.0 - Math.abs(x) / (root.width * 0.75))

        MouseArea {
            id: dragArea
            anchors.fill: parent
            enabled: root.slidable
            drag.target: cardContainer
            drag.axis: Drag.XAxis
            drag.minimumX: -root.width
            drag.maximumX: root.width

            onReleased: {
                if (Math.abs(cardContainer.x) > 75) {
                    root.slideOffset = cardContainer.x
                    dismissAnim.start()
                } else {
                    root.slideOffset = 0
                    cardContainer.x = 0
                }
            }

            onClicked: (mouse) => {
                if (Math.abs(cardContainer.x) > 10) return;
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

        HoverHandler { id: hover }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                IconImage {
                    implicitWidth: 26
                    implicitHeight: 26
                    source: root.notification && root.notification.image !== ""
                        ? root.notification.image
                        : Quickshell.iconPath(root.notification ? root.notification.appIcon : "", "dialog-information")
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.notification ? root.notification.appName : ""
                        color: Theme.fgDim
                        font.pixelSize: 11
                        font.family: Theme.fontFamilySans
                        font.weight: Theme.fontWeight
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.notification ? root.notification.summary : ""
                        color: Theme.fg
                        font.weight: Theme.fontWeight
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: 22
                    height: 22
                    radius: width / 2
                    color: closeHover.hovered ? Theme.surfaceVariant : "transparent"
                    Layout.alignment: Qt.AlignTop

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: closeHover.hovered ? Theme.red : Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler { id: closeHover }
                    TapHandler {
                        onTapped: {
                            if (root.notification)
                                NotificationServer.dismiss(root.notification)
                        }
                    }
                }
            }

            Text {
                text: root.notification ? root.notification.body : ""
                textFormat: Text.StyledText
                color: Theme.fgDim
                font.family: Theme.fontFamilySans
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: text !== ""
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: root.notification && root.notification.actions !== undefined && root.notification.actions !== null && root.notification.actions.length > 0

                Repeater {
                    model: root.notification ? root.notification.actions : []
                    delegate: Rectangle {
                        visible: modelData.identifier !== "default"
                        width: visible ? implicitWidth : 0
                        height: visible ? implicitHeight : 0

                        color: hoverAction.hovered ? Theme.accent : Theme.surfaceVariant
                        radius: Theme.radiusSmall
                        implicitWidth: actionText.implicitWidth + 18
                        implicitHeight: 24

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text || modelData.identifier || ""
                            color: hoverAction.hovered ? Theme.bgDark : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 11
                            font.weight: Theme.fontWeight
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
}
