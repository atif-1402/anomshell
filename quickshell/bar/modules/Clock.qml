import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    property var theme: ({})

    implicitWidth:  clockRow.implicitWidth
    implicitHeight: 28

    function updateTime() {
        const now  = new Date()
        let   h    = now.getHours()
        const min  = String(now.getMinutes()).padStart(2, "0")
        const ampm = h >= 12 ? "PM" : "AM"
        h = h % 12 || 12
        timeText.text = String(h).padStart(2, "0") + ":" + min
        ampmText.text = ampm
        dateText.text = Qt.formatDate(now, "ddd, d MMM")
    }

    Timer {
        interval: 15000
        running:  true
        repeat:   true
        onTriggered: updateTime()
    }

    Component.onCompleted: updateTime()

    // ── Clock row ─────────────────────────────────
    Row {
        id:      clockRow
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                id:             timeText
                anchors.verticalCenter: parent.verticalCenter
                color:          theme.fg || "#cdd6f4"
                font.pixelSize: 13
                font.family:    "JetBrainsMono Nerd Font"
                font.weight:    Font.Medium
            }

            Text {
                id:             ampmText
                anchors.verticalCenter: parent.verticalCenter
                color:          theme.accent || "#89b4fa"
                font.pixelSize: 9
                font.family:    "JetBrainsMono Nerd Font"
                font.weight:    Font.Medium
                bottomPadding:  1
            }
        }

        Rectangle {
            width:                  1
            height:                 10
            color:                  theme.dim || "#45475a"
            opacity:                0.5
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id:             dateText
            anchors.verticalCenter: parent.verticalCenter
            color:          theme.muted || "#585b70"
            font.pixelSize: 11
            font.family:    "JetBrainsMono Nerd Font"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered:    calWindow.showing = true
        onExited:     hideTimer.start()
    }

    Timer {
        id:       hideTimer
        interval: 300
        onTriggered: if (!calHover.containsMouse) calWindow.showing = false
    }

    // ── Calendar window ───────────────────────────
    PanelWindow {
        id:      calWindow
        visible: true

        property bool showing: false

        anchors { top: true }
        margins { top: 44; }

        implicitWidth:  220
        implicitHeight: showing ? calCol.implicitHeight + 16 : 0

        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Behavior on implicitHeight {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        property int viewYear:  new Date().getFullYear()
        property int viewMonth: new Date().getMonth()
        property var today:     new Date()

        function daysInMonth(y, m)     { return new Date(y, m + 1, 0).getDate() }
        function firstDayOfMonth(y, m) {
            const d = new Date(y, m, 1).getDay()
            return (d + 6) % 7
        }
        function prevMonth() {
            if (viewMonth === 0) { viewMonth = 11; viewYear-- }
            else viewMonth--
        }
        function nextMonth() {
            if (viewMonth === 11) { viewMonth = 0; viewYear++ }
            else viewMonth++
        }

        Rectangle {
            anchors.fill: parent
            radius:       10
            color:        root.theme.bg    || "#1e1e2e"
            border.color: root.theme.dim   || "#45475a"
            border.width: 1
            clip:         true
            opacity:      calWindow.showing ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id:           calHover
                anchors.fill: parent
                hoverEnabled: true
                onEntered:    hideTimer.stop()
                onExited:     hideTimer.start()
            }

            Column {
                id:            calCol
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.top:   parent.top
                anchors.margins: 8
                spacing:       6

                // ── Month header ──────────────────
                Row {
                    width:  parent.width
                    height: 20

                    Text {
                        text:           "‹"
                        color:          root.theme.muted || "#585b70"
                        font.pixelSize: 14
                        font.family:    "JetBrainsMono Nerd Font"
                        width:          20
                        horizontalAlignment: Text.AlignHCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    calWindow.prevMonth()
                        }
                    }

                    Text {
                        text: {
                            const months = ["January","February","March","April",
                                            "May","June","July","August",
                                            "September","October","November","December"]
                            return months[calWindow.viewMonth] + " " + calWindow.viewYear
                        }
                        color:          root.theme.fg || "#cdd6f4"
                        font.pixelSize: 11
                        font.family:    "JetBrainsMono Nerd Font"
                        font.weight:    Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        width:          parent.width - 40

                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        text:           "›"
                        color:          root.theme.muted || "#585b70"
                        font.pixelSize: 14
                        font.family:    "JetBrainsMono Nerd Font"
                        width:          20
                        horizontalAlignment: Text.AlignHCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    calWindow.nextMonth()
                        }
                    }
                }

                // ── Day labels ────────────────────
                Row {
                    width:   parent.width
                    spacing: 0
                    Repeater {
                        model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                        Text {
                            width:          calCol.width / 7
                            text:           modelData
                            color:          root.theme.muted || "#585b70"
                            font.pixelSize: 9
                            font.family:    "JetBrainsMono Nerd Font"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // ── Day grid ──────────────────────
                Grid {
                    id:      dayGrid
                    columns: 7
                    width:   parent.width
                    spacing: 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        model: {
                            const offset = calWindow.firstDayOfMonth(calWindow.viewYear, calWindow.viewMonth)
                            const days   = calWindow.daysInMonth(calWindow.viewYear, calWindow.viewMonth)
                            return offset + days
                        }

                        Item {
                            width:  dayGrid.width / 7
                            height: 22

                            readonly property int  dayNum:  index - calWindow.firstDayOfMonth(calWindow.viewYear, calWindow.viewMonth) + 1
                            readonly property bool isValid: index >= calWindow.firstDayOfMonth(calWindow.viewYear, calWindow.viewMonth)
                            readonly property bool isToday:
                                isValid &&
                                dayNum === calWindow.today.getDate() &&
                                calWindow.viewMonth === calWindow.today.getMonth() &&
                                calWindow.viewYear  === calWindow.today.getFullYear()

                            Rectangle {
                                anchors.centerIn: parent
                                width:   18; height: 18; radius: 9
                                color:   isToday ? (root.theme.accent || "#89b4fa") : "transparent"
                                visible: isValid
                            }

                            Text {
                                anchors.centerIn: parent
                                text:    isValid ? dayNum : ""
                                color:   isToday
                                         ? (root.theme.bg || "#1e1e2e")
                                         : (root.theme.fg || "#cdd6f4")
                                opacity: isValid ? 1.0 : 0.0
                                font.pixelSize: 10
                                font.family:    "JetBrainsMono Nerd Font"
                                font.weight:    isToday ? Font.Bold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}