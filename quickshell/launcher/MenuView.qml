import QtQuick
import QtQuick.Layouts
import Quickshell.Io


Item {
    id: root

    property var    theme:  ({})
    property bool   active: false

    signal closeRequested
    signal appsRequested
    signal themesRequested

    property var    navStack:   []
    property string searchText: ""
    property bool   globalSearch: false

    readonly property var    currentItems: navStack.length > 0 ? navStack[navStack.length - 1].items : menuRoot
    readonly property string currentTitle: navStack.length > 0 ? navStack[navStack.length - 1].title : "Go"

    property var menuRoot: MenuData.buildTree()
    property var flatItems: []

    Component.onCompleted: flatItems = flattenTree(menuRoot, [])

    function flattenTree(items, path) {
        var result = []
        for (var i = 0; i < items.length; i++) {
            var item = items[i]
            var itemPath = path.concat(item.label)
            if (item.children) {
                var sub = flattenTree(item.children, itemPath)
                for (var j = 0; j < sub.length; j++)
                    result.push(sub[j])
            } else if (item.cmd || item.terminal || item.action) {
                result.push({
                    icon:     item.icon || "",
                    label:    item.label,
                    path:     path,
                    cmd:      item.cmd || null,
                    terminal: item.terminal || null,
                    action:   item.action || null,
                })
            }
        }
        return result
    }

    function getGlobalResults(query) {
        if (!query || query.trim() === "") return []
        var q = query.trim().toLowerCase()
        var out = []
        for (var i = 0; i < flatItems.length; i++) {
            var item = flatItems[i]
            if (item.label.toLowerCase().indexOf(q) !== -1)
                out.push(item)
        }
        return out
    }

    function reset() {
        navStack      = []
        searchText    = ""
        globalSearch  = false
        currentPage.searchText = ""
        currentPage.applyFilter()
        currentPage.selectedIdx = 0
        globalPage.selectedIdx  = 0
    }

    function pushPage(title, items) {
        var newStack = navStack.slice()
        newStack.push({ title: title, items: items })
        slideDir = 1
        navStack = newStack
        searchText = ""
        Qt.callLater(function() {
            currentPage.searchText = ""
            currentPage.applyFilter()
            currentPage.selectedIdx = 0
        })
    }

    function popPage() {
        if (navStack.length === 0) {
            root.closeRequested()
            return
        }
        var newStack = navStack.slice(0, navStack.length - 1)
        slideDir = -1
        navStack = newStack
        searchText = ""
        Qt.callLater(function() {
            currentPage.searchText = ""
            currentPage.applyFilter()
        })
    }

    function handleKey(e) {
        if (e.key === Qt.Key_Escape) {
            if (globalSearch) {
                globalSearch = false
                searchText   = ""
                globalPage.selectedIdx = 0
            } else {
                popPage()
            }
            e.accepted = true
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (globalSearch)
                globalPage.activateSelected()
            else
                currentPage.activateSelected()
            e.accepted = true
        } else if (e.key === Qt.Key_Down) {
            if (globalSearch) globalPage.moveDown()
            else              currentPage.moveDown()
            e.accepted = true
        } else if (e.key === Qt.Key_Up) {
            if (globalSearch) globalPage.moveUp()
            else              currentPage.moveUp()
            e.accepted = true
        } else if (e.key === Qt.Key_Backspace) {
            if (searchText.length > 0) {
                searchText = searchText.slice(0, -1)
                if (globalSearch) {
                    if (searchText === "") {
                        globalSearch = false
                        globalPage.selectedIdx = 0
                    } else {
                        globalPage.updateResults(searchText)
                    }
                } else {
                    currentPage.searchText = searchText
                }
            } else if (navStack.length > 0) {
                popPage()
            }
            e.accepted = true
        } else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32) {
            searchText += e.text
            if (navStack.length === 0) {
                globalSearch = true
                globalPage.updateResults(searchText)
                globalPage.selectedIdx = 0
            } else {
                currentPage.searchText = searchText
            }
            e.accepted = true
        }
    }

    function activateItem(item) {
        if (item.children !== undefined && item.children.length > 0) {
            pushPage(item.label, item.children)
            return
        }
        if (item.action === "openKeybindings") {
            runCmd("quickshell ipc call openKeybindings handle")
            root.closeRequested()
            return
        }
        if (item.action === "themes") {
            root.themesRequested()
            return
        }
        if (item.action === "openThemes") {
            runCmd("quickshell ipc call openThemes handle")
            root.closeRequested()
            return
        }        
        if (item.action === "apps") {
            root.appsRequested()
            return
        }
        if (item.action === "about") {
            runCmd("omarchy-launch-about")
            root.closeRequested()
            return
        }
        if (item.cmd) {
            runCmd(item.cmd)
            root.closeRequested()
            return
        }
        if (item.terminal) {
            runTerminal(item.terminal)
            root.closeRequested()
            return
        }
    }

    property int _cmdSeq: 0

    function runCmd(cmd) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash", "-c", ""]; running: false }',
            root, "dynProc" + (++_cmdSeq)
        )
        proc.command = ["bash", "-c", "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; " + cmd]
        proc.running = true
    }

    function runTerminal(cmd) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash", "-c", ""]; running: false }',
            root, "dynProc" + (++_cmdSeq)
        )
        proc.command = [
            "bash", "-c",
            "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; " +
            "setsid uwsm-app -- xdg-terminal-exec --app-id=org.omarchy.terminal --title=Omarchy -e bash -c " +
            "'omarchy-show-logo; " + cmd.replace(/'/g, "'\\''") + "; if (( $? != 130 )); then omarchy-show-done; fi'"
        ]
        proc.running = true
    }

    property int slideDir: 1

    ColumnLayout {
        anchors.fill: parent
        spacing:      6

        // breadcrumb
        Row {
            Layout.fillWidth: true
            spacing:          4
            visible:          navStack.length > 0 && !globalSearch

            opacity: navStack.length > 0 && !globalSearch ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           ""
                color:          Qt.alpha(theme.accent || "#89b4fa", 0.7)
                font.pixelSize: 11
                font.family:    "JetBrainsMono Nerd Font"
                MouseArea {
                    anchors.fill:    parent
                    anchors.margins: -6
                    cursorShape:     Qt.PointingHandCursor
                    onClicked:       root.popPage()
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "Go"
                color:          Qt.alpha(theme.muted || "#585b70", 0.5)
                font.pixelSize: 9
                font.family:    "JetBrainsMono Nerd Font"
            }

            Repeater {
                model: navStack
                Row {
                    spacing: 4
                    Text {
                        text:           "›"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.4)
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text:           modelData.title
                        color:          index === navStack.length - 1
                            ? (theme.fg || "#cdd6f4")
                            : Qt.alpha(theme.muted || "#585b70", 0.5)
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                        font.weight:    index === navStack.length - 1 ? Font.Medium : Font.Normal
                    }
                }
            }
        }

        // global search label
        Row {
            Layout.fillWidth: true
            spacing:          6
            visible:          globalSearch
            opacity:          globalSearch ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "󰍉"
                color:          theme.accent || "#89b4fa"
                font.pixelSize: 11
                font.family:    "JetBrainsMono Nerd Font"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "Global Search"
                color:          theme.accent || "#89b4fa"
                font.pixelSize: 9
                font.family:    "JetBrainsMono Nerd Font"
                font.weight:    Font.Medium
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           "— esc to cancel"
                color:          Qt.alpha(theme.muted || "#585b70", 0.4)
                font.pixelSize: 9
                font.family:    "JetBrainsMono Nerd Font"
            }
        }

        // search bar
        Rectangle {
            Layout.fillWidth: true
            height:           34
            radius:           8
            color:            Qt.alpha(theme.dim || "#45475a", 0.4)
            border.color:     globalSearch
                ? (theme.accent || "#89b4fa")
                : active
                    ? Qt.alpha(theme.accent || "#89b4fa", 0.6)
                    : Qt.alpha(theme.accent || "#89b4fa", 0.3)
            border.width:     globalSearch ? 2 : 1

            Behavior on border.color {
                ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on border.width {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            // subtle glow behind search bar when active
            Rectangle {
                anchors.fill:    parent
                anchors.margins: -1
                radius:          9
                color:           "transparent"
                border.color:    Qt.alpha(theme.accent || "#89b4fa", globalSearch ? 0.15 : active ? 0.08 : 0)
                border.width:    4

                Behavior on border.color {
                    ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }

            Row {
                anchors.fill:        parent
                anchors.leftMargin:  10
                anchors.rightMargin: 10
                spacing:             8

                // search icon — rotates slightly when global search activates
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "󰍉"
                    color:          globalSearch
                        ? (theme.accent || "#89b4fa")
                        : Qt.alpha(theme.accent || "#89b4fa", 0.7)
                    font.pixelSize: 13
                    font.family:    "JetBrainsMono Nerd Font"

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    transform: Rotation {
                        origin.x: 7; origin.y: 7
                        angle: globalSearch ? -15 : 0
                        Behavior on angle {
                            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           root.searchText !== ""
                        ? root.searchText
                        : globalSearch
                            ? "Search everything…"
                            : "Search " + root.currentTitle.toLowerCase() + "…"
                    color:          root.searchText !== ""
                        ? (theme.fg || "#cdd6f4")
                        : Qt.alpha(theme.muted || "#585b70", 0.4)
                    font.pixelSize: 12
                    font.family:    "JetBrainsMono Nerd Font"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                // blinking cursor
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width:  1.5
                    height: 13
                    radius: 1
                    color:  theme.accent || "#89b4fa"
                    SequentialAnimation on opacity {
                        loops:   Animation.Infinite
                        running: root.active
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
                        onClicked: {
                            root.searchText        = ""
                            globalSearch           = false
                            currentPage.searchText = ""
                            globalPage.selectedIdx = 0
                        }
                    }
                }
            }
        }

        // hint row
        Row {
            Layout.fillWidth: true
            Text {
                text: globalSearch
                    ? (globalPage.results ? globalPage.results.length : 0) + " results"
                    : (currentPage.filteredItems ? currentPage.filteredItems.length : 0) + " items"
                color:          Qt.alpha(theme.muted || "#585b70", 0.45)
                font.pixelSize: 9
                font.family:    "JetBrainsMono Nerd Font"
            }
            Item { width: 1; height: 1; Layout.fillWidth: true }
            Text {
                text: globalSearch
                    ? "↑↓  ↵ open  esc cancel"
                    : navStack.length > 0
                        ? "⌫ back  ↑↓  ↵ open  esc"
                        : "type to search  ↑↓  ↵ open  esc"
                color:          Qt.alpha(theme.muted || "#585b70", 0.3)
                font.pixelSize: 9
                font.family:    "JetBrainsMono Nerd Font"
            }
        }

        // page container
        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            clip:              true

            // normal menu page
            MenuPage {
                id:      currentPage
                width:   parent.width
                height:  parent.height
                items:   root.currentItems
                theme:   root.theme
                title:   root.currentTitle
                visible: !globalSearch

                onItemActivated: (item) => root.activateItem(item)
                onBackRequested: root.popPage()

                property real slideOffset: 0
                property real slideFade:   1
                transform: Translate { x: currentPage.slideOffset }
                opacity:   currentPage.slideFade

                onItemsChanged: {
                    slideOffset = root.slideDir * parent.width
                    slideFade   = 0
                    slideInAnim.restart()
                }

                ParallelAnimation {
                    id: slideInAnim
                    NumberAnimation {
                        target:      currentPage
                        property:    "slideOffset"
                        to:          0
                        duration:    220
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target:      currentPage
                        property:    "slideFade"
                        to:          1
                        duration:    180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // global search results
            Item {
                id:      globalPage
                width:   parent.width
                height:  parent.height
                visible: globalSearch
                opacity: globalSearch ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                property var results:     []
                property int selectedIdx: 0

                function updateResults(query) {
                    results      = root.getGlobalResults(query)
                    selectedIdx  = 0
                    lv.positionViewAtIndex(0, ListView.Beginning)
                }

                function moveDown() {
                    if (selectedIdx < results.length - 1) {
                        selectedIdx++
                        lv.positionViewAtIndex(selectedIdx, ListView.Contain)
                    }
                }

                function moveUp() {
                    if (selectedIdx > 0) {
                        selectedIdx--
                        lv.positionViewAtIndex(selectedIdx, ListView.Contain)
                    }
                }

                function activateSelected() {
                    if (results.length > 0)
                        root.activateItem(results[selectedIdx])
                }

                ListView {
                    id:           lv
                    anchors.fill: parent
                    model:        globalPage.results
                    spacing:      2
                    clip:         true

                    delegate: Item {
                        id:     globalDelegate
                        width:  lv.width
                        height: 38

                        property bool isSelected: index === globalPage.selectedIdx
                        property var  mitem:      globalPage.results[index] || {}

                        opacity: 0
                        transform: Translate { id: globalTx; x: -6 }

                        Component.onCompleted: {
                            globalAppearTimer.interval = index * 18
                            globalAppearTimer.start()
                        }

                        Timer {
                            id:     globalAppearTimer
                            repeat: false
                            onTriggered: globalAppearAnim.start()
                        }

                        ParallelAnimation {
                            id: globalAppearAnim
                            NumberAnimation {
                                target:   globalDelegate
                                property: "opacity"
                                from: 0; to: 1
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target:   globalTx
                                property: "x"
                                from: -6; to: 0
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill:    parent
                            anchors.margins: 1
                            radius:          7
                            color:           isSelected
                                ? Qt.alpha(theme.accent || "#89b4fa", 0.18)
                                : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 100; easing.type: Easing.OutCubic }
                            }

                            // left accent bar
                            Rectangle {
                                width:   2
                                height:  isSelected ? 20 : 0
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
                                id: iconText
                                anchors.left:           parent.left
                                anchors.leftMargin:     14
                                anchors.verticalCenter: parent.verticalCenter
                                text:           mitem.icon || ""
                                color:          isSelected
                                    ? (theme.accent || "#89b4fa")
                                    : Qt.alpha(theme.fg || "#cdd6f4", 0.55)
                                font.pixelSize: 13
                                font.family:    "JetBrainsMono Nerd Font"
                                width:          20

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }

                            Column {
                                anchors.left:           iconText.right
                                anchors.leftMargin:     10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing:                2

                                Text {
                                    text:           mitem.label || ""
                                    color:          isSelected
                                        ? (theme.fg || "#cdd6f4")
                                        : Qt.alpha(theme.fg || "#cdd6f4", 0.75)
                                    font.pixelSize: 12
                                    font.family:    "JetBrainsMono Nerd Font"
                                    font.weight:    isSelected ? Font.Medium : Font.Normal

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }
                                }

                                Text {
                                    visible:        mitem.path && mitem.path.length > 0
                                    text:           mitem.path ? mitem.path.join(" › ") : ""
                                    color:          Qt.alpha(theme.muted || "#585b70", isSelected ? 0.6 : 0.35)
                                    font.pixelSize: 9
                                    font.family:    "JetBrainsMono Nerd Font"

                                    Behavior on color {
                                        ColorAnimation { duration: 120 }
                                    }
                                }
                            }

                            Text {
                                anchors.right:          parent.right
                                anchors.rightMargin:    10
                                anchors.verticalCenter: parent.verticalCenter
                                visible:                mitem.terminal !== undefined && mitem.terminal !== null
                                text:                   "󰆍"
                                color:                  Qt.alpha(theme.muted || "#585b70", isSelected ? 0.6 : 0.3)
                                font.pixelSize:         10
                                font.family:            "JetBrainsMono Nerd Font"

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onEntered:    globalPage.selectedIdx = index
                            onClicked:    root.activateItem(mitem)
                        }
                    }
                }
            }
        }
    }
}