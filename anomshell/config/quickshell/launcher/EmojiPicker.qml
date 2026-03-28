import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    property bool showing: false
    property var theme: ({})
    property string searchText: ""
    property int selectedIdx: 0
    property var allEmojis: []
    property var filteredEmojis: []
    property string copiedEmoji: ""
    property bool showCopied: false
    property string loadError: ""

    anchors { bottom: true }
    margins { bottom: 5 }

    implicitWidth: 560
    implicitHeight: 420
    color: "transparent"
    exclusiveZone: 0
    visible: showing

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onShowingChanged: {
        if (showing) {
            if (allEmojis.length === 0)
                loadEmojis()
            searchText = ""
            applyFilter()
            selectedIdx = 0
            focusTimer.start()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: focusScope.forceActiveFocus()
    }

    Timer {
        id: copiedTimer
        interval: 900
        repeat: false
        onTriggered: showCopied = false
    }

    function shellEscape(str) {
        return (str || "")
            .replace(/\\/g, "\\\\")
            .replace(/"/g, "\\\"")
            .replace(/\$/g, "\\$")
            .replace(/`/g, "\\`")
    }

    function copyEmoji(emoji) {
        const safe = shellEscape(emoji)
        Quickshell.execDetached(["bash", "-lc", "printf '%s' \"" + safe + "\" | wl-copy"])
        copiedEmoji = emoji
        showCopied = true
        copiedTimer.restart()
        showing = false
    }

    function applyFilter() {
        const q = searchText.trim().toLowerCase()
        var out = []
        for (var i = 0; i < allEmojis.length; i++) {
            const name = (allEmojis[i].name || "").toLowerCase()
            if (q === "" || name.indexOf(q) !== -1)
                out.push(allEmojis[i])
        }
        filteredEmojis = out
        selectedIdx = 0
        if (listView.count > 0)
            listView.positionViewAtIndex(0, ListView.Beginning)
    }

    function loadEmojis() {
        loadError = ""
        emojiScanner.stdout.buf = []
        emojiScanner.running = false
        emojiScanner.running = true
    }

    Process {
        id: emojiScanner
        command: ["bash", "-lc",
            "FILE=''; " +
            "for f in /usr/share/unicode/emoji/emoji-test.txt /usr/share/emoji/emoji-test.txt; do " +
            "  if [ -f \"$f\" ]; then FILE=\"$f\"; break; fi; " +
            "done; " +
            "[ -z \"$FILE\" ] && echo '__ERROR__|emoji-test.txt not found. Install unicode-emoji.' && exit 0; " +
            "awk -F'# ' '/;[[:space:]]*fully-qualified/ { " +
            "  n=split($2,a,\" \"); " +
            "  emoji=a[1]; name=\"\"; " +
            "  for(i=3;i<=n;i++){ name = name (name==\"\"?a[i]:\" \" a[i]); } " +
            "  if (emoji!=\"\" && name!=\"\") print emoji \"|\" name; " +
            "}' \"$FILE\""
        ]
        running: false
        stdout: SplitParser {
            property var buf: []
            onRead: data => {
                const line = data.trim()
                if (!line) return
                const p = line.split("|")
                if (p.length < 2) return
                const emoji = p[0]
                const name = p.slice(1).join("|")
                if (emoji === "__ERROR__") {
                    root.loadError = name
                    return
                }
                if (emoji && name)
                    buf.push({ emoji: emoji, name: name })
            }
        }
        onExited: {
            root.allEmojis = emojiScanner.stdout.buf.slice()
            emojiScanner.stdout.buf = []
            applyFilter()
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                if (root.searchText.length > 0) {
                    root.searchText = ""
                    applyFilter()
                } else {
                    root.showing = false
                }
                e.accepted = true
            } else if (e.key === Qt.Key_Down) {
                if (selectedIdx < filteredEmojis.length - 1) selectedIdx++
                listView.positionViewAtIndex(selectedIdx, ListView.Contain)
                e.accepted = true
            } else if (e.key === Qt.Key_Up) {
                if (selectedIdx > 0) selectedIdx--
                listView.positionViewAtIndex(selectedIdx, ListView.Contain)
                e.accepted = true
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                if (filteredEmojis.length > 0)
                    copyEmoji(filteredEmojis[selectedIdx].emoji)
                e.accepted = true
            } else if (e.key === Qt.Key_Backspace) {
                if (root.searchText.length > 0) {
                    root.searchText = root.searchText.slice(0, -1)
                    applyFilter()
                } else {
                    root.showing = false
                }
                e.accepted = true
            } else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32) {
                root.searchText += e.text
                applyFilter()
                e.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip: true

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

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Row {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "😊"
                        color: theme.accent || "#89b4fa"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Emoji Picker"
                        color: theme.fg || "#cdd6f4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: showCopied ? ("Copied " + copiedEmoji) : ""
                        color: theme.accent || "#89b4fa"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        opacity: showCopied ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: Qt.alpha(theme.dim || "#45475a", 0.4)
                    border.color: theme.accent || "#89b4fa"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍉"
                            color: theme.accent || "#89b4fa"
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: searchText !== "" ? searchText : "Search emoji…"
                            color: searchText !== ""
                                ? (theme.fg || "#cdd6f4")
                                : Qt.alpha(theme.muted || "#585b70", 0.4)
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
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
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: filteredEmojis

                    delegate: Rectangle {
                        width: listView.width
                        height: 32
                        radius: 8
                        color: index === selectedIdx
                            ? Qt.alpha(theme.accent || "#89b4fa", 0.16)
                            : Qt.alpha(theme.dim || "#45475a", 0.18)
                        border.color: index === selectedIdx
                            ? Qt.alpha(theme.accent || "#89b4fa", 0.45)
                            : Qt.alpha(theme.dim || "#45475a", 0.25)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.emoji
                                font.pixelSize: 16
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: theme.fg || "#cdd6f4"
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight
                                width: parent.width - 30
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: selectedIdx = index
                            onClicked: copyEmoji(modelData.emoji)
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: filteredEmojis.length === 0
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: loadError !== "" ? "Emoji list not found" : "No matches"
                            color: theme.fg || "#cdd6f4"
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: loadError !== "" ? loadError : "Try another search term."
                            color: theme.muted || "#585b70"
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }
            }
        }
    }
}
