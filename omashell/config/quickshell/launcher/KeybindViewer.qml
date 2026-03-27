import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    property bool showing: false
    property var  theme:   ({})
    readonly property string homeDir: Quickshell.env("HOME") || ""

    anchors { bottom: true }
    margins { bottom: 5 }

    implicitWidth:  700
    implicitHeight: 420
    color:          "transparent"
    exclusiveZone:  0
    visible:        showing

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var    allBindings:      []
    property var    filteredBindings: []
    property string searchText:       ""
    property int    selectedIdx:      0

    onSearchTextChanged: applyFilter()

    function applyFilter() {
        var q = searchText.trim().toLowerCase()
        var out = []
        for (var i = 0; i < allBindings.length; i++) {
            var b = allBindings[i]
            if (q === "" ||
                b.combo.toLowerCase().indexOf(q) !== -1 ||
                b.action.toLowerCase().indexOf(q) !== -1)
                out.push(b)
        }
        filteredBindings = out
        selectedIdx = 0
        listView.positionViewAtIndex(0, ListView.Beginning)
    }

    Process {
        id: keybindLoader
        command: [root.homeDir + "/.local/bin/qs-keybinds-list"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line === "") return
                var idx = line.indexOf("|")
                if (idx === -1) return
                var combo  = line.substring(0, idx).trim()
                var action = line.substring(idx + 1).trim()
                if (combo && action)
                    root.allBindings.push({ combo: combo, action: action })
            }
        }
        onExited: {
            root.allBindings = root.allBindings.slice()
            root.applyFilter()
        }
    }

    FocusScope {
        id:           focusScope
        anchors.fill: parent
        focus:        true

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                if (root.searchText.length > 0)
                    root.searchText = ""
                else
                    root.showing = false
                e.accepted = true
            } else if (e.key === Qt.Key_Down) {
                if (root.selectedIdx < root.filteredBindings.length - 1) {
                    root.selectedIdx++
                    listView.positionViewAtIndex(root.selectedIdx, ListView.Contain)
                }
                e.accepted = true
            } else if (e.key === Qt.Key_Up) {
                if (root.selectedIdx > 0) {
                    root.selectedIdx--
                    listView.positionViewAtIndex(root.selectedIdx, ListView.Contain)
                }
                e.accepted = true
            } else if (e.key === Qt.Key_Backspace) {
                if (root.searchText.length > 0)
                    root.searchText = root.searchText.slice(0, -1)
                else
                    root.showing = false
                e.accepted = true
            } else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32) {
                root.searchText += e.text
                e.accepted = true
            }
        }

        Rectangle {
            id:           card
            anchors.fill: parent
            radius:       12
            color:        theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip:         true

            opacity: root.showing ? 1 : 0
            transform: Translate {
                y: root.showing ? 0 : 20
                Behavior on y {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                anchors.fill:    parent
                anchors.margins: 12
                spacing:         8

                Row {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           "󰌌"
                        color:          theme.accent || "#89b4fa"
                        font.pixelSize: 13
                        font.family:    "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           "Keybindings"
                        color:          theme.fg || "#cdd6f4"
                        font.pixelSize: 12
                        font.family:    "JetBrainsMono Nerd Font"
                        font.weight:    Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           root.filteredBindings.length + " bindings"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.45)
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           "✕"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.5)
                        font.pixelSize: 10
                        MouseArea {
                            anchors.fill:    parent
                            anchors.margins: -6
                            cursorShape:     Qt.PointingHandCursor
                            onClicked:       root.showing = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:           34
                    radius:           8
                    color:            Qt.alpha(theme.dim || "#45475a", 0.4)
                    border.color:     theme.accent || "#89b4fa"
                    border.width:     1

                    Row {
                        anchors.fill:        parent
                        anchors.leftMargin:  10
                        anchors.rightMargin: 10
                        spacing:             8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           "󰍉"
                            color:          theme.accent || "#89b4fa"
                            font.pixelSize: 13
                            font.family:    "JetBrainsMono Nerd Font"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           root.searchText !== ""
                                ? root.searchText
                                : "Search keybindings…"
                            color:          root.searchText !== ""
                                ? (theme.fg || "#cdd6f4")
                                : Qt.alpha(theme.muted || "#585b70", 0.4)
                            font.pixelSize: 12
                            font.family:    "JetBrainsMono Nerd Font"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width:  1.5
                            height: 13
                            radius: 1
                            color:  theme.accent || "#89b4fa"
                            SequentialAnimation on opacity {
                                loops:   Animation.Infinite
                                running: root.showing
                                NumberAnimation { to: 0; duration: 530; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 530; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible:        root.searchText !== ""
                            text:           "✕"
                            color:          Qt.alpha(theme.muted || "#585b70", 0.5)
                            font.pixelSize: 10
                            MouseArea {
                                anchors.fill:    parent
                                anchors.margins: -4
                                cursorShape:     Qt.PointingHandCursor
                                onClicked:       root.searchText = ""
                            }
                        }
                    }
                }

                Row {
                    Layout.fillWidth: true
                    Text {
                        text:           root.filteredBindings.length + " results"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.4)
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text:           "↑↓ nav  esc close"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.3)
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                    }
                }

                Item {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    visible:           root.allBindings.length === 0

                    Text {
                        anchors.centerIn: parent
                        text:             "Loading keybindings…"
                        color:            Qt.alpha(theme.muted || "#585b70", 0.4)
                        font.pixelSize:   11
                        font.family:      "JetBrainsMono Nerd Font"
                    }
                }

                ListView {
                    id:                listView
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    visible:           root.allBindings.length > 0
                    model:             root.filteredBindings
                    spacing:           2
                    clip:              true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width:  2
                    }

                    delegate: Item {
                        id:     delegateItem
                        width:  listView.width
                        height: 30

                        property bool isSelected: index === root.selectedIdx
                        property var  bdata:      root.filteredBindings[index] || {}

                        opacity: 0
                        Component.onCompleted: {
                            appearTimer.interval = Math.min(index * 8, 200)
                            appearTimer.start()
                        }

                        Timer {
                            id:     appearTimer
                            repeat: false
                            onTriggered: appearAnim.start()
                        }

                        NumberAnimation {
                            id:          appearAnim
                            target:      delegateItem
                            property:    "opacity"
                            from:        0; to: 1
                            duration:    150
                            easing.type: Easing.OutCubic
                        }

                        Rectangle {
                            anchors.fill:    parent
                            anchors.margins: 1
                            radius:          6
                            color:           isSelected
                                ? Qt.alpha(theme.accent || "#89b4fa", 0.12)
                                : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 80 }
                            }

                            Rectangle {
                                width:   2
                                height:  isSelected ? 14 : 0
                                radius:  1
                                color:   theme.accent || "#89b4fa"
                                anchors.left:           parent.left
                                anchors.leftMargin:     3
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on height {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }
                            }

                            Row {
                                anchors.fill:        parent
                                anchors.leftMargin:  12
                                anchors.rightMargin: 8
                                spacing:             0

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height:  20
                                    width:   comboText.implicitWidth + 16
                                    radius:  4
                                    color:   isSelected
                                        ? Qt.alpha(theme.accent || "#89b4fa", 0.2)
                                        : Qt.alpha(theme.dim || "#45475a", 0.5)

                                    Behavior on color {
                                        ColorAnimation { duration: 100 }
                                    }

                                    Text {
                                        id:               comboText
                                        anchors.centerIn: parent
                                        text:             bdata.combo || ""
                                        color:            isSelected
                                            ? (theme.accent || "#89b4fa")
                                            : Qt.alpha(theme.fg || "#cdd6f4", 0.8)
                                        font.pixelSize:   9
                                        font.family:      "JetBrainsMono Nerd Font"
                                        font.weight:      Font.Medium

                                        Behavior on color {
                                            ColorAnimation { duration: 100 }
                                        }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:           "  →  "
                                    color:          Qt.alpha(theme.muted || "#585b70", 0.4)
                                    font.pixelSize: 9
                                    font.family:    "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:           bdata.action || ""
                                    color:          isSelected
                                        ? (theme.fg || "#cdd6f4")
                                        : Qt.alpha(theme.fg || "#cdd6f4", 0.65)
                                    font.pixelSize: 10
                                    font.family:    "JetBrainsMono Nerd Font"
                                    elide:          Text.ElideRight
                                    width:          listView.width - comboText.implicitWidth - 80

                                    Behavior on color {
                                        ColorAnimation { duration: 100 }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onEntered:    root.selectedIdx = index
                        }
                    }
                }
            }
        }
    }

    onShowingChanged: {
        if (showing) {
            searchText  = ""
            selectedIdx = 0
            applyFilter()
            focusTimer.start()
        }
    }

    Timer {
        id:       focusTimer
        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }
}
