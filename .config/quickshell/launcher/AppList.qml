import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: list

    signal launched()

    property var allApps:      []
    property var filteredApps: []
    property int selectedIdx:  0
    property var theme:        ({})
    property string currentQuery: ""

    function filter(query) {
        currentQuery = query || ""
        selectedIdx = 0
        if (!query || query.trim() === "") {
            filteredApps = allApps.slice(0, 50)
            return
        }
        const q   = query.toLowerCase()
        const sw  = allApps.filter(a => a.name.toLowerCase().startsWith(q))
        const inc = allApps.filter(a =>
            !a.name.toLowerCase().startsWith(q) &&
            a.name.toLowerCase().includes(q)
        )
        filteredApps = sw.concat(inc).slice(0, 50)
    }

    function launchSelected() {
        if (filteredApps.length === 0) return
        const idx = Math.max(0, Math.min(selectedIdx, filteredApps.length - 1))
        launchApp(filteredApps[idx])
    }

    function moveDown() {
        if (filteredApps.length === 0) return
        selectedIdx = Math.min(selectedIdx + 1, filteredApps.length - 1)
        lv.positionViewAtIndex(selectedIdx, ListView.Visible)
    }

    function moveUp() {
        if (filteredApps.length === 0) return
        selectedIdx = Math.max(selectedIdx - 1, 0)
        lv.positionViewAtIndex(selectedIdx, ListView.Visible)
    }

    function launchApp(app) {
        if (!app || !app.exec) return
        const cmd = app.exec.replace(/%[uUfFdDnNickvm]/g, "").trim()
        if (!cmd) return
        Quickshell.execDetached(["bash", "-c", cmd])
        list.launched()
    }

    function reload() {
        parser.stdout.apps = []
        parser.stdout.buf = ""
        parser.running = false
        parser.running = true
    }

    Process {
        id: parser
        command: ["bash", "-c", `
            for f in /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop ~/Desktop/*.desktop; do
                [ -f "$f" ] || continue
                name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
                exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
                nodisplay=$(grep -m1 '^NoDisplay=' "$f" | cut -d= -f2-)
                [ "$nodisplay" = "true" ] && continue
                [ -z "$name" ] && continue
                [ -z "$exec" ] && continue
                printf '%s|%s\n' "$name" "$exec"
            done | sort -u
        `]
        running: true
        stdout: SplitParser {
            property var apps: []
            property string buf: ""
            onRead: data => {
                buf += data + "\n"
                const lines = buf.split("\n")
                buf = lines.pop()

                for (const line of lines) {
                    const trimmed = (line || "").trim()
                    if (!trimmed)
                        continue
                    const splitIdx = trimmed.indexOf("|")
                    if (splitIdx === -1)
                        continue
                    const name = trimmed.slice(0, splitIdx).trim()
                    const exec = trimmed.slice(splitIdx + 1).trim()
                    if (name && exec)
                        apps.push({ name: name, exec: exec })
                }
            }
        }
        onExited: {
            list.allApps       = parser.stdout.apps.slice()
            parser.stdout.apps = []
            parser.stdout.buf = ""
            list.filter(list.currentQuery)
        }
    }

    ListView {
        id:           lv
        anchors.fill: parent
        model:        list.filteredApps
        clip:         true
        spacing:      1

        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 120; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id:     appDelegate
            width:  lv.width
            height: 28

            property bool isSelected: index === list.selectedIdx

            // fade + slide in on appear
            opacity: 0
            transform: Translate { id: appDelegateTx; x: -6 }

            Component.onCompleted: {
                appAppearTimer.interval = Math.min(index * 12, 300)
                appAppearTimer.start()
            }

            Timer {
                id:     appAppearTimer
                repeat: false
                onTriggered: appAppearAnim.start()
            }

            ParallelAnimation {
                id: appAppearAnim
                NumberAnimation {
                    target:      appDelegate
                    property:    "opacity"
                    from: 0; to: 1
                    duration:    160
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target:      appDelegateTx
                    property:    "x"
                    from: -6; to: 0
                    duration:    160
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill:    parent
                anchors.margins: 0
                radius:          6
                color:           isSelected
                    ? Qt.alpha(theme.accent || "#89b4fa", 0.12)
                    : rowMa.containsMouse
                        ? Qt.alpha(theme.dim || "#45475a", 0.35)
                        : "transparent"
                border.color:    isSelected
                    ? Qt.alpha(theme.accent || "#89b4fa", 0.25)
                    : "transparent"
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: 100; easing.type: Easing.OutCubic }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 100 }
                }

                // left accent bar
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

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left:           parent.left
                    anchors.leftMargin:     14
                    text:           modelData.name
                    color:          isSelected
                        ? (theme.fg || "#cdd6f4")
                        : Qt.alpha(theme.fg || "#cdd6f4", 0.5)
                    font.pixelSize: 11
                    font.family:    "JetBrainsMono Nerd Font"
                    font.weight:    isSelected ? Font.Medium : Font.Normal

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                // exec hint — only on selected, far right
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right:          parent.right
                    anchors.rightMargin:    10
                    visible:                isSelected
                    opacity:                isSelected ? 1 : 0
                    text:                   modelData.exec.split(" ")[0].split("/").pop()
                    color:                  Qt.alpha(theme.muted || "#585b70", 0.4)
                    font.pixelSize:         9
                    font.family:            "JetBrainsMono Nerd Font"

                    Behavior on opacity {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }
            }

            MouseArea {
                id:           rowMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:    list.selectedIdx = index
                onClicked: {
                    list.selectedIdx = index
                    list.launchApp(modelData)
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width:  2
        }

        Behavior on contentY {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }
}
