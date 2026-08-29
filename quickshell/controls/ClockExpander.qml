import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    property string targetScreenName: ""
    property int monthOffset: 0
    property bool twentyFourHour: false
    readonly property bool expanded: UiState.clockMenuVisible
        && (UiState.clockScreen === "" || UiState.clockScreen === targetScreenName)
    readonly property int topWidth: Math.max(300,
        Math.ceil(topLayout.implicitWidth + Theme.pillPaddingHoriz * 2))
    readonly property int bodyHeight: 284
    readonly property date displayMonth: new Date(clock.date.getFullYear(),
        clock.date.getMonth() + monthOffset, 1)
    property real reveal: expanded ? 1 : 0

    implicitWidth: topWidth
    implicitHeight: Theme.barHeight + bodyHeight * reveal
    clip: true
    focus: expanded
    border.color: expanded || reveal > 0 ? Theme.accent
        : (root.hovered ? Theme.accentGlow : Theme.bgDark)

    Behavior on reveal {
        NumberAnimation { duration: 105; easing.type: Easing.OutQuart }
    }

    onExpandedChanged: {
        if (expanded) {
            monthOffset = 0
            Qt.callLater(() => root.forceActiveFocus())
        }
    }

    function cellDate(index) {
        const mondayOffset = (displayMonth.getDay() + 6) % 7
        return new Date(displayMonth.getFullYear(), displayMonth.getMonth(),
            index - mondayOffset + 1)
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Keys.onEscapePressed: UiState.clockMenuVisible = false
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) {
            UiState.clockTab = "calendar"
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            UiState.clockTab = UiState.clockTab === "calendar" ? "time" : "calendar"
            event.accepted = true
        }
    }

    Item {
        id: topButton
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.barHeight

        RowLayout {
            id: topLayout
            anchors.centerIn: parent
            spacing: 0

            Text {
                text: "󰥔  "
                color: Theme.purple
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
            }
            Text {
                text: Qt.formatDateTime(clock.date, "h:mm AP") + "   "
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
            }
            Text {
                text: "󰃭  "
                color: Theme.blue
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
            }
            Text {
                text: Qt.formatDateTime(clock.date, "MMM d")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: UiState.toggleClock(root.targetScreenName)
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight - 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.borderWidth
        anchors.rightMargin: Theme.borderWidth
        height: 1
        color: Theme.surface
        visible: root.reveal > 0
    }

    Item {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bodyHeight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: UiState.clockTab === "calendar" ? Theme.accent
                        : (calendarTabHover.hovered ? Theme.surface : Theme.bgLight)
                    Text {
                        anchors.centerIn: parent
                        text: "󰃭  Calendar"
                        color: UiState.clockTab === "calendar" ? Theme.bgDark : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Theme.fontWeight
                    }
                    HoverHandler { id: calendarTabHover }
                    TapHandler { onTapped: UiState.clockTab = "calendar" }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: UiState.clockTab === "time" ? Theme.accent
                        : (timeTabHover.hovered ? Theme.surface : Theme.bgLight)
                    Text {
                        anchors.centerIn: parent
                        text: "󰥔  Time"
                        color: UiState.clockTab === "time" ? Theme.bgDark : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Theme.fontWeight
                    }
                    HoverHandler { id: timeTabHover }
                    TapHandler { onTapped: UiState.clockTab = "time" }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                visible: UiState.clockTab === "calendar"
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 8
                    color: previousHover.hovered ? Theme.accent : Theme.bgLight
                    Text {
                        anchors.centerIn: parent
                        text: "󰁍"
                        color: previousHover.hovered ? Theme.bgDark : Theme.fg
                        font.family: Theme.fontFamily
                    }
                    HoverHandler { id: previousHover }
                    TapHandler { onTapped: root.monthOffset-- }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(root.displayMonth, "MMMM yyyy")
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 14
                    font.weight: Theme.fontWeight
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 8
                    color: nextHover.hovered ? Theme.accent : Theme.bgLight
                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        color: nextHover.hovered ? Theme.bgDark : Theme.fg
                        font.family: Theme.fontFamily
                    }
                    HoverHandler { id: nextHover }
                    TapHandler { onTapped: root.monthOffset++ }
                }
            }

            Grid {
                id: weekdayGrid
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                visible: UiState.clockTab === "calendar"
                columns: 7

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Text {
                        required property string modelData
                        width: weekdayGrid.width / 7
                        height: weekdayGrid.height
                        text: modelData
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Theme.fontWeight
                    }
                }
            }

            Grid {
                id: dayGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: UiState.clockTab === "calendar"
                columns: 7
                columnSpacing: 4
                rowSpacing: 4

                Repeater {
                    model: 42

                    Rectangle {
                        id: dayCell
                        required property int index
                        readonly property date dayDate: root.cellDate(index)
                        readonly property bool inMonth: dayDate.getMonth() === root.displayMonth.getMonth()
                            && dayDate.getFullYear() === root.displayMonth.getFullYear()
                        readonly property bool isToday: root.sameDay(dayDate, clock.date)
                        width: (dayGrid.width - dayGrid.columnSpacing * 6) / 7
                        height: (dayGrid.height - dayGrid.rowSpacing * 5) / 6
                        radius: 7
                        color: isToday ? Theme.accent
                            : (dayHover.hovered ? Theme.surface : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.dayDate.getDate()
                            color: dayCell.isToday ? Theme.bgDark
                                : (dayCell.inMonth ? Theme.fg : Theme.fgMuted)
                            opacity: dayCell.inMonth || dayCell.isToday ? 1 : 0.55
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: dayCell.isToday ? Font.Bold : Font.Medium
                        }

                        HoverHandler { id: dayHover }
                        TapHandler {
                            onTapped: {
                                if (dayCell.dayDate < root.displayMonth)
                                    root.monthOffset--
                                else if (!dayCell.inMonth)
                                    root.monthOffset++
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: UiState.clockTab === "time"
                spacing: 10

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDateTime(clock.date,
                        root.twentyFourHour ? "HH:mm:ss" : "hh:mm:ss AP")
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")
                    color: Theme.fgDim
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 13
                    font.weight: Theme.fontWeight
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "t")
                    color: Theme.purple
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 164
                    Layout.preferredHeight: 32
                    radius: 8
                    color: timeFormatHover.hovered ? Theme.accent : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: root.twentyFourHour ? "Use 12-hour clock" : "Use 24-hour clock"
                        color: timeFormatHover.hovered ? Theme.bgDark : Theme.fg
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 11
                        font.weight: Theme.fontWeight
                    }
                    HoverHandler { id: timeFormatHover }
                    TapHandler { onTapped: root.twentyFourHour = !root.twentyFourHour }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
