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

    implicitWidth:  380
    color:          "transparent"
    exclusiveZone:  0
    visible:        showing

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var    themes:         []
    property string searchText:     ""
    property int    selectedIdx:    0
    property var    filteredThemes: []

    onThemesChanged:     applyFilter()
    onSearchTextChanged: applyFilter()

    function applyFilter() {
        var q = searchText.trim().toLowerCase()
        var out = []
        for (var i = 0; i < themes.length; i++) {
            if (q === "" || themes[i].name.toLowerCase().indexOf(q) !== -1)
                out.push(themes[i])
        }
        filteredThemes = out
        selectedIdx = 0
        if (grid.count > 0)
            grid.positionViewAtIndex(0, GridView.Beginning)
    }

    property string scanScript: '
USER_DIR="$HOME/.config/omarchy/themes"
SYS_DIR="$HOME/.local/share/omarchy/themes"
CURRENT=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null)
SEEN=""
for dir in "$USER_DIR"/*/ "$SYS_DIR"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    echo "$SEEN" | grep -qx "$name" && continue
    SEEN="$SEEN
$name"
    preview="$dir/preview.png"
    colors="$dir/colors.toml"
    [ -f "$preview" ] || continue
    [ -f "$colors" ] || continue
    bg=$(grep -m1 "^background" "$colors" | grep -o "#[0-9a-fA-F]*" | head -1)
    fg=$(grep -m1 "^foreground" "$colors" | grep -o "#[0-9a-fA-F]*" | head -1)
    accent=$(grep -m1 "^accent" "$colors" | grep -o "#[0-9a-fA-F]*" | head -1)
    c1=$(grep -m1 "^color1" "$colors" | grep -o "#[0-9a-fA-F]*" | head -1)
    c2=$(grep -m1 "^color2" "$colors" | grep -o "#[0-9a-fA-F]*" | head -1)
    c3=$(grep -m1 "^color3" "$colors" | grep -o "#[0-9a-fA-F]*" | head -1)
    c4=$(grep -m1 "^color4" "$colors" | grep -o "#[0-9a-fA-F]*" | head -1)
    active=0
    [ "$name" = "$CURRENT" ] && active=1
    printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n" \
        "$name" "$preview" \
        "${bg:-#1e1e2e}" "${fg:-#cdd6f4}" "${accent:-#89b4fa}" \
        "${c1:-#f38ba8}" "${c2:-#a6e3a1}" "${c3:-#f9e2af}" "${c4:-#89b4fa}" \
        "$active"
done | sort
'

    function reload() {
        themeScanner.stdout.buf = []
        themeScanner.running = false
        themeScanner.running = true
    }

    Process {
        id: themeScanner
        command: ["bash", "-c", root.scanScript]
        running: true
        stdout: SplitParser {
            property var buf: []
            onRead: data => {
                var p = data.trim().split("|")
                if (p.length >= 10 && p[0].trim() !== "") {
                    buf.push({
                        name:    p[0],
                        preview: p[1],
                        bg:      p[2],
                        fg:      p[3],
                        accent:  p[4],
                        c1:      p[5],
                        c2:      p[6],
                        c3:      p[7],
                        c4:      p[8],
                        active:  p[9].trim() === "1",
                    })
                }
            }
        }
        onExited: {
            root.themes = themeScanner.stdout.buf.slice()
            themeScanner.stdout.buf = []
        }
    }

    Process {
        id: themesDirWatcher
        command: ["bash", "-lc",
            "USER_DIR=\"$HOME/.config/omarchy/themes\"; " +
            "SYS_DIR=\"$HOME/.local/share/omarchy/themes\"; " +
            "if command -v inotifywait >/dev/null 2>&1 && ([ -d \"$USER_DIR\" ] || [ -d \"$SYS_DIR\" ]); then " +
            "  exec inotifywait -m -e create,delete \"$USER_DIR\" \"$SYS_DIR\" 2>/dev/null; " +
            "else " +
            "  last=''; " +
            "  while true; do " +
            "    cur=$(find \"$USER_DIR\" \"$SYS_DIR\" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tr '\\n' '|'); " +
            "    if [ \"$cur\" != \"$last\" ]; then printf 'changed\\n'; last=\"$cur\"; fi; " +
            "    sleep 4; " +
            "  done; " +
            "fi"
        ]
        running: true
        stdout: SplitParser {
            onRead: _ => root.reload()
        }
    }

    property int _cmdSeq: 0

    function applyTheme(name) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash","-c",""]; running: false }',
            root, "applyProc" + (++_cmdSeq)
        )
        proc.onExited.connect(function() { proc.destroy() })
        proc.command = [
            "bash", "-c",
            "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; omarchy-theme-set '" + name + "'"
        ]
        proc.running = true
        root.showing = false
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
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                if (root.filteredThemes.length > 0)
                    root.applyTheme(root.filteredThemes[root.selectedIdx].name)
                e.accepted = true
            } else if (e.key === Qt.Key_Down) {
                if (root.selectedIdx < root.filteredThemes.length - 1) {
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
            id:           card
            anchors.fill: parent
            radius:       12
            color:        theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip:         true

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
                anchors.fill:    parent
                anchors.margins: 10
                spacing:         6

                // header
                Row {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           "󰏘"
                        color:          theme.accent || "#89b4fa"
                        font.pixelSize: 12
                        font.family:    "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           "Themes"
                        color:          theme.fg || "#cdd6f4"
                        font.pixelSize: 11
                        font.family:    "JetBrainsMono Nerd Font"
                        font.weight:    Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           root.filteredThemes.length + " themes"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.45)
                        font.pixelSize: 8
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

                // search bar
                Rectangle {
                    Layout.fillWidth: true
                    height:           30
                    radius:           7
                    color:            Qt.alpha(theme.dim || "#45475a", 0.4)
                    border.color:     theme.accent || "#89b4fa"
                    border.width:     1

                    Row {
                        anchors.fill:        parent
                        anchors.leftMargin:  8
                        anchors.rightMargin: 8
                        spacing:             6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           "󰍉"
                            color:          theme.accent || "#89b4fa"
                            font.pixelSize: 12
                            font.family:    "JetBrainsMono Nerd Font"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           root.searchText !== "" ? root.searchText : "Search themes…"
                            color:          root.searchText !== ""
                                ? (theme.fg || "#cdd6f4")
                                : Qt.alpha(theme.muted || "#585b70", 0.4)
                            font.pixelSize: 11
                            font.family:    "JetBrainsMono Nerd Font"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width:  1.5
                            height: 12
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
                            font.pixelSize: 9
                            MouseArea {
                                anchors.fill:    parent
                                anchors.margins: -4
                                cursorShape:     Qt.PointingHandCursor
                                onClicked:       root.searchText = ""
                            }
                        }
                    }
                }

                // hint
                Text {
                    text:           "↑↓ nav  ↵ apply  esc close"
                    color:          Qt.alpha(theme.muted || "#585b70", 0.3)
                    font.pixelSize: 8
                    font.family:    "JetBrainsMono Nerd Font"
                }

                // loading
                Item {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    visible:           root.themes.length === 0

                    Text {
                        anchors.centerIn: parent
                        text:             "Loading themes…"
                        color:            Qt.alpha(theme.muted || "#585b70", 0.4)
                        font.pixelSize:   10
                        font.family:      "JetBrainsMono Nerd Font"
                    }
                }

                // single column list
                GridView {
                    id:                grid
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    visible:           root.themes.length > 0
                    clip:              true
                    cellWidth:         root.implicitWidth - 20
                    cellHeight:        Math.floor(cellWidth * 0.50) + 28
                    model:             root.filteredThemes

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width:  2
                    }

                    delegate: Item {
                        id:     delegateItem
                        width:  grid.cellWidth
                        height: grid.cellHeight

                        property var  tdata:      root.filteredThemes[index] || {}
                        property bool isActive:   tdata.active || false
                        property bool isSelected: index === root.selectedIdx
                        property bool isHovered:  false

                        opacity: 0
                        Component.onCompleted: {
                            appearTimer.interval = Math.min(index * 20, 400)
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
                            duration:    200
                            easing.type: Easing.OutCubic
                        }

                        Rectangle {
                            anchors.fill:    parent
                            anchors.margins: 3
                            radius:          7
                            color:           tdata.bg || "#1e1e2e"
                            border.color:    isSelected
                                ? (theme.accent || "#89b4fa")
                                : isActive
                                    ? Qt.alpha(theme.accent || "#89b4fa", 0.6)
                                    : isHovered
                                        ? Qt.alpha(theme.accent || "#89b4fa", 0.3)
                                        : Qt.alpha(theme.dim || "#45475a", 0.2)
                            border.width:    isSelected ? 2 : isActive ? 2 : 1
                            clip:            true

                            Behavior on border.color {
                                ColorAnimation { duration: 120 }
                            }
                            Behavior on border.width {
                                NumberAnimation { duration: 120 }
                            }

                            // selection glow
                            Rectangle {
                                anchors.fill:    parent
                                anchors.margins: -1
                                radius:          8
                                color:           "transparent"
                                border.color:    Qt.alpha(theme.accent || "#89b4fa", isSelected ? 0.2 : 0)
                                border.width:    4
                                Behavior on border.color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            scale: isHovered ? 1.01 : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }

                            Image {
                                id:            previewImg
                                anchors.top:   parent.top
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height:        parent.height - 28
                                source:        tdata.preview ? ("file://" + tdata.preview) : ""
                                fillMode:      Image.PreserveAspectCrop
                                asynchronous:  true
                                clip:          true
                                opacity:       status === Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color:        tdata.bg || "#1e1e2e"
                                    visible:      previewImg.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text:             "󰸌"
                                        color:            Qt.alpha(tdata.fg || "#cdd6f4", 0.15)
                                        font.pixelSize:   24
                                        font.family:      "JetBrainsMono Nerd Font"
                                    }
                                }
                            }

                            // active badge
                            Rectangle {
                                visible:         isActive
                                anchors.top:     parent.top
                                anchors.right:   parent.right
                                anchors.margins: 4
                                width:  14; height: 14
                                radius: 7
                                color:  theme.accent || "#89b4fa"

                                Text {
                                    anchors.centerIn: parent
                                    text:             "✓"
                                    color:            "#000000"
                                    font.pixelSize:   7
                                    font.weight:      Font.Bold
                                }
                            }

                            // bottom bar
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left:   parent.left
                                anchors.right:  parent.right
                                height:         28
                                color:          Qt.alpha(tdata.bg || "#1e1e2e", 0.95)

                                Row {
                                    anchors.fill:        parent
                                    anchors.leftMargin:  8
                                    anchors.rightMargin: 8
                                    spacing:             0

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text:           tdata.name || ""
                                        color:          isSelected
                                            ? (theme.accent || "#89b4fa")
                                            : (tdata.fg || "#cdd6f4")
                                        font.pixelSize: 9
                                        font.family:    "JetBrainsMono Nerd Font"
                                        font.weight:    isSelected ? Font.Medium : Font.Normal
                                        elide:          Text.ElideRight
                                        width:          parent.width - 44

                                        Behavior on color {
                                            ColorAnimation { duration: 120 }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3

                                        Repeater {
                                            model: [tdata.accent, tdata.c1, tdata.c2, tdata.c3]
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width:  7; height: 7
                                                radius: 3
                                                color:  modelData || "#ffffff"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onEntered: {
                                delegateItem.isHovered = true
                                root.selectedIdx = index
                            }
                            onExited:  delegateItem.isHovered = false
                            onClicked: root.applyTheme(tdata.name)
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
            focusTimer.start()
            root.reload()
        }
    }

    Timer {
        id:       focusTimer
        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }
}
