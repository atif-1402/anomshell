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

    anchors { left: true; top: true; bottom: true }
    margins { left: 5; top: 5; bottom: 5 }

    implicitWidth: 380
    color: "transparent"
    exclusiveZone: 0
    visible: showing

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var backgrounds: []
    property var filteredBackgrounds: []
    property string searchText: ""
    property int selectedIdx: 0

    onBackgroundsChanged: applyFilter()
    onSearchTextChanged: applyFilter()

    function applyFilter() {
        const q = searchText.trim().toLowerCase()
        const out = []
        for (let i = 0; i < backgrounds.length; i++) {
            const b = backgrounds[i]
            if (q === "" || b.name.toLowerCase().indexOf(q) !== -1)
                out.push(b)
        }
        filteredBackgrounds = out
        selectedIdx = 0
        if (grid.count > 0)
            grid.positionViewAtIndex(0, GridView.Beginning)
    }

    function shellQuote(s) {
        if (s === undefined || s === null)
            return "''"
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function reload() {
        scanner.stdout.buf = []
        scanner.running = false
        scanner.running = true
    }

    function applySelected() {
        if (filteredBackgrounds.length === 0)
            return
        const idx = Math.max(0, Math.min(selectedIdx, filteredBackgrounds.length - 1))
        applyBackground(filteredBackgrounds[idx].path)
    }

    function applyBackground(path) {
        if (!path || path === "")
            return
        applyProc.command = [
            "bash", "-lc",
            "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; omarchy-theme-bg-set " + shellQuote(path)
        ]
        applyProc.running = false
        applyProc.running = true
    }

    property string scanScript: '
THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null)
THEME_BACKGROUNDS_PATH="$HOME/.config/omarchy/current/theme/backgrounds/"
USER_BACKGROUNDS_PATH="$HOME/.config/omarchy/backgrounds/$THEME_NAME/"
CURRENT_BACKGROUND_LINK="$HOME/.config/omarchy/current/background"

if [[ -L "$CURRENT_BACKGROUND_LINK" ]]; then
  CURRENT_BACKGROUND=$(readlink "$CURRENT_BACKGROUND_LINK")
else
  CURRENT_BACKGROUND=""
fi

mapfile -d "" -t BACKGROUNDS < <(find -L "$USER_BACKGROUNDS_PATH" "$THEME_BACKGROUNDS_PATH" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)

for bg in "${BACKGROUNDS[@]}"; do
  [ -f "$bg" ] || continue
  name=$(basename "$bg")
  active=0
  [[ "$bg" == "$CURRENT_BACKGROUND" ]] && active=1
  printf "%s|%s|%s\\n" "$name" "$bg" "$active"
done
'

    Process {
        id: scanner
        command: ["bash", "-lc", root.scanScript]
        running: true
        stdout: SplitParser {
            property var buf: []
            onRead: data => {
                const p = data.trim().split("|")
                if (p.length >= 3 && p[0].trim() !== "") {
                    buf.push({
                        name: p[0],
                        path: p[1],
                        active: p[2].trim() === "1",
                        source: p[1] ? ("file://" + p[1]) : ""
                    })
                }
            }
        }
        onExited: {
            root.backgrounds = scanner.stdout.buf.slice()
            scanner.stdout.buf = []
        }
    }

    Process {
        id: applyProc
        command: ["bash", "-lc", "true"]
        running: false
        onExited: {
            root.reload()
            root.showing = false
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                if (root.searchText.length > 0)
                    root.searchText = ""
                else
                    root.showing = false
                e.accepted = true
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                root.applySelected()
                e.accepted = true
            } else if (e.key === Qt.Key_Down) {
                if (root.selectedIdx < root.filteredBackgrounds.length - 1) {
                    root.selectedIdx++
                    grid.positionViewAtIndex(root.selectedIdx, GridView.Contain)
                }
                e.accepted = true
            } else if (e.key === Qt.Key_Up) {
                if (root.selectedIdx > 0) {
                    root.selectedIdx--
                    grid.positionViewAtIndex(root.selectedIdx, GridView.Contain)
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
            id: card
            anchors.fill: parent
            radius: 12
            color: theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip: true

            opacity: root.showing ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            transform: Translate {
                x: root.showing ? 0 : -20
                Behavior on x {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Row {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: theme.accent || "#89b4fa"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Backgrounds"
                        color: theme.fg || "#cdd6f4"
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.filteredBackgrounds.length + " images"
                        color: Qt.alpha(theme.muted || "#585b70", 0.45)
                        font.pixelSize: 8
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: Qt.alpha(theme.muted || "#585b70", 0.5)
                        font.pixelSize: 10
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showing = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 7
                    color: Qt.alpha(theme.dim || "#45475a", 0.4)
                    border.color: theme.accent || "#89b4fa"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍉"
                            color: theme.accent || "#89b4fa"
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.searchText !== "" ? root.searchText : "Search backgrounds..."
                            color: root.searchText !== ""
                                ? (theme.fg || "#cdd6f4")
                                : Qt.alpha(theme.muted || "#585b70", 0.4)
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1.5
                            height: 12
                            radius: 1
                            color: theme.accent || "#89b4fa"
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: root.showing
                                NumberAnimation { to: 0; duration: 530; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 530; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.searchText !== ""
                            text: "✕"
                            color: Qt.alpha(theme.muted || "#585b70", 0.5)
                            font.pixelSize: 9
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.searchText = ""
                            }
                        }
                    }
                }

                Text {
                    text: "↑↓ nav  ↵ apply  esc close"
                    color: Qt.alpha(theme.muted || "#585b70", 0.3)
                    font.pixelSize: 8
                    font.family: "JetBrainsMono Nerd Font"
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.backgrounds.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "Loading backgrounds..."
                        color: Qt.alpha(theme.muted || "#585b70", 0.4)
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.backgrounds.length > 0
                    clip: true
                    cellWidth: root.implicitWidth - 20
                    cellHeight: Math.floor(cellWidth * 0.50) + 28
                    model: root.filteredBackgrounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 2
                    }

                    delegate: Item {
                        id: delegateItem
                        width: grid.cellWidth
                        height: grid.cellHeight

                        property var bdata: root.filteredBackgrounds[index] || {}
                        property bool isActive: bdata.active || false
                        property bool isSelected: index === root.selectedIdx
                        property bool isHovered: false

                        opacity: 0
                        Component.onCompleted: {
                            appearTimer.interval = Math.min(index * 20, 400)
                            appearTimer.start()
                        }

                        Timer {
                            id: appearTimer
                            repeat: false
                            onTriggered: appearAnim.start()
                        }

                        NumberAnimation {
                            id: appearAnim
                            target: delegateItem
                            property: "opacity"
                            from: 0; to: 1
                            duration: 200
                            easing.type: Easing.OutCubic
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 7
                            color: theme.bg || "#1e1e2e"
                            border.color: isSelected
                                ? (theme.accent || "#89b4fa")
                                : isActive
                                    ? Qt.alpha(theme.accent || "#89b4fa", 0.6)
                                    : isHovered
                                        ? Qt.alpha(theme.accent || "#89b4fa", 0.3)
                                        : Qt.alpha(theme.dim || "#45475a", 0.2)
                            border.width: isSelected ? 2 : isActive ? 2 : 1
                            clip: true

                            Behavior on border.color {
                                ColorAnimation { duration: 120 }
                            }
                            Behavior on border.width {
                                NumberAnimation { duration: 120 }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -1
                                radius: 8
                                color: "transparent"
                                border.color: Qt.alpha(theme.accent || "#89b4fa", isSelected ? 0.2 : 0)
                                border.width: 4
                                Behavior on border.color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            scale: isHovered ? 1.01 : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }

                            Image {
                                id: previewImg
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height - 28
                                source: bdata.source || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                clip: true
                                opacity: status === Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: theme.bg || "#1e1e2e"
                                    visible: previewImg.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰸌"
                                        color: Qt.alpha(theme.fg || "#cdd6f4", 0.15)
                                        font.pixelSize: 24
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                            }

                            Rectangle {
                                visible: isActive
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 4
                                width: 14
                                height: 14
                                radius: 7
                                color: theme.accent || "#89b4fa"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: "#000000"
                                    font.pixelSize: 7
                                    font.weight: Font.Bold
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 28
                                color: Qt.alpha(theme.bg || "#1e1e2e", 0.95)

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    text: bdata.name || ""
                                    color: isSelected
                                        ? (theme.accent || "#89b4fa")
                                        : (theme.fg || "#cdd6f4")
                                    font.pixelSize: 9
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.weight: isSelected ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                delegateItem.isHovered = true
                                root.selectedIdx = index
                            }
                            onExited: delegateItem.isHovered = false
                            onClicked: root.applyBackground(bdata.path)
                        }
                    }
                }
            }
        }
    }

    onShowingChanged: {
        if (showing) {
            searchText = ""
            selectedIdx = 0
            focusTimer.start()
            root.reload()
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }
}
