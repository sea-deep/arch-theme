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
    readonly property int bodyHeight: 312
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
                text: Qt.formatDateTime(clock.date, root.twentyFourHour ? "H:mm" : "h:mm AP") + "   "
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

        Item {
            anchors.fill: parent
            anchors.margins: 14

            RowLayout {
                id: tabsRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 30
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    color: UiState.clockTab === "calendar" ? Theme.accent
                        : (calendarTabHover.hovered ? Theme.surface : Theme.bgLight)
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰃭"
                            color: UiState.clockTab === "calendar" ? Theme.bgDark : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Calendar"
                            color: UiState.clockTab === "calendar" ? Theme.bgDark : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    HoverHandler { id: calendarTabHover }
                    TapHandler { onTapped: UiState.clockTab = "calendar" }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    color: UiState.clockTab === "time" ? Theme.accent
                        : (timeTabHover.hovered ? Theme.surface : Theme.bgLight)
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰥔"
                            color: UiState.clockTab === "time" ? Theme.bgDark : Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Time"
                            color: UiState.clockTab === "time" ? Theme.bgDark : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    HoverHandler { id: timeTabHover }
                    TapHandler { onTapped: UiState.clockTab = "time" }
                }
            }

            Item {
                anchors.top: tabsRow.bottom
                anchors.topMargin: 14
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    anchors.fill: parent
                    visible: UiState.clockTab === "calendar"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 26

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 26
                                height: 26
                                radius: 6
                                color: previousHover.hovered ? Theme.accent : Theme.bgLight
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰁍"
                                    color: previousHover.hovered ? Theme.bgDark : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                }
                                HoverHandler { id: previousHover }
                                TapHandler { onTapped: root.monthOffset-- }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Qt.formatDate(root.displayMonth, "MMMM yyyy")
                                color: Theme.fg
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 14
                                font.weight: Theme.fontWeight
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 26
                                height: 26
                                radius: 6
                                color: nextHover.hovered ? Theme.accent : Theme.bgLight
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅂"
                                    color: nextHover.hovered ? Theme.bgDark : Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                }
                                HoverHandler { id: nextHover }
                                TapHandler { onTapped: root.monthOffset++ }
                            }
                        }

                        Grid {
                            id: weekdayGrid
                            Layout.alignment: Qt.AlignHCenter
                            columns: 7
                            columnSpacing: 6
                            
                            Repeater {
                                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                Item {
                                    width: 28
                                    height: 18
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: Theme.fgDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Theme.fontWeight
                                    }
                                }
                            }
                        }

                        Grid {
                            id: dayGrid
                            Layout.alignment: Qt.AlignHCenter
                            columns: 7
                            columnSpacing: 6
                            rowSpacing: 6

                            Repeater {
                                model: 42

                                Item {
                                    id: dayCellWrapper
                                    required property int index
                                    width: 28
                                    height: 28

                                    Rectangle {
                                        id: dayCell
                                        readonly property date dayDate: root.cellDate(dayCellWrapper.index)
                                        readonly property bool inMonth: dayDate.getMonth() === root.displayMonth.getMonth()
                                            && dayDate.getFullYear() === root.displayMonth.getFullYear()
                                        readonly property bool isToday: root.sameDay(dayDate, clock.date)
                                        
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        radius: 6
                                        color: isToday ? Theme.accent
                                            : (dayHover.hovered ? Theme.surface : "transparent")

                                        Text {
                                            anchors.centerIn: parent
                                            text: dayCell.dayDate.getDate()
                                            color: dayCell.isToday ? Theme.bgDark
                                                : (dayCell.inMonth ? Theme.fg : Theme.fgMuted)
                                            opacity: dayCell.inMonth || dayCell.isToday ? 1 : 0.3
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
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }

                Item {
                    anchors.fill: parent
                    visible: UiState.clockTab === "time"

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, root.twentyFourHour ? "H:mm:ss" : "h:mm:ss AP")
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")
                            color: Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 13
                            font.weight: Theme.fontWeight
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, "t")
                            color: Theme.purple
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        
                        Item { Layout.preferredHeight: 6 }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 26
                            radius: 6
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
                    }
                }
            }
        }
    }
}
