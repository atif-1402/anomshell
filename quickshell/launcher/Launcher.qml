import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: launcher

    property bool   showing: false
    property var    theme:   ({})
    property string mode:    "menu"

    anchors { left: true; right: true; top: true; bottom: true }

    color:         "transparent"
    exclusiveZone: 0
    visible:       showing

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    FocusScope {
        id:           focusScope
        anchors.fill: parent
        focus:        true

        // fullscreen background — click outside closes
        MouseArea {
            anchors.fill: parent
            onClicked:    launcher.showing = false
        }

        Keys.onPressed: e => {
            if (mode === "menu") {
                menuView.handleKey(e)
            } else {
                if (e.key === Qt.Key_Escape) {
                    mode = "menu"
                    e.accepted = true
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    appList.launchSelected()
                    e.accepted = true
                } else if (e.key === Qt.Key_Down) {
                    appList.moveDown()
                    e.accepted = true
                } else if (e.key === Qt.Key_Up) {
                    appList.moveUp()
                    e.accepted = true
                } else if (e.key === Qt.Key_Backspace) {
                    if (appSearchText.length > 0) {
                        appSearchText = appSearchText.slice(0, -1)
                        appList.filter(appSearchText)
                    } else {
                        mode = "menu"
                    }
                    e.accepted = true
                } else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32) {
                    appSearchText += e.text
                    appList.filter(appSearchText)
                    e.accepted = true
                }
            }
        }

        // card — positioned at bottom center
        Rectangle {
            id:                       card
            width:                    420
            height:                   400
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     5
            anchors.horizontalCenter: parent.horizontalCenter
            radius:       12
            color:        theme.bg  || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip:         true

            opacity: launcher.showing ? 1 : 0
            transform: Translate {
                y: launcher.showing ? 0 : 20
                Behavior on y {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // block clicks from reaching background MouseArea
            MouseArea {
                anchors.fill: parent
                onClicked:    {}
            }

            // ── menu mode ─────────────────────────────────────────
            MenuView {
                id:              menuView
                anchors.fill:    parent
                anchors.margins: 10
                theme:           launcher.theme
                active:          launcher.showing && launcher.mode === "menu"
                visible:         launcher.mode === "menu"

                onCloseRequested: launcher.showing = false
                onAppsRequested: {
                    appSearchText = ""
                    appList.filter("")
                    appList.selectedIdx = 0
                    launcher.mode = "apps"
                }
                onThemesRequested: {
                    launcher.showing = false
                }
            }

            // ── apps mode ─────────────────────────────────────────
            ColumnLayout {
                anchors.fill:      parent
                anchors.margins:   10
                anchors.topMargin: 10
                spacing:           6
                visible:           launcher.mode === "apps"

                Row {
                    Layout.fillWidth: true
                    spacing: 6

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
                            onClicked:       launcher.mode = "menu"
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           "Go › Apps"
                        color:          theme.fg || "#cdd6f4"
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                        font.weight:    Font.Medium
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
                            text:           appSearchText !== "" ? appSearchText : "Search applications…"
                            color:          appSearchText !== ""
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
                                running: launcher.showing && launcher.mode === "apps"
                                NumberAnimation { to: 0; duration: 530; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 530; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible:        appSearchText !== ""
                            text:           "✕"
                            color:          Qt.alpha(theme.muted || "#585b70", 0.5)
                            font.pixelSize: 10
                            MouseArea {
                                anchors.fill:    parent
                                anchors.margins: -4
                                cursorShape:     Qt.PointingHandCursor
                                onClicked: {
                                    appSearchText = ""
                                    appList.filter("")
                                }
                            }
                        }
                    }
                }

                Row {
                    Layout.fillWidth: true
                    Text {
                        text:           appList.filteredApps.length + " apps"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.45)
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                    }
                    Item { width: 1; height: 1; Layout.fillWidth: true }
                    Text {
                        text:           "↑↓  ↵ open  ⌫/esc back"
                        color:          Qt.alpha(theme.muted || "#585b70", 0.3)
                        font.pixelSize: 9
                        font.family:    "JetBrainsMono Nerd Font"
                    }
                }

                AppList {
                    id:                appList
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    theme:             launcher.theme
                    onLaunched:        launcher.showing = false
                }
            }
        }
    }

    property string appSearchText: ""

    onShowingChanged: {
        if (showing) {
            if (mode === "apps") {
                appSearchText = ""
                appList.filter("")
                appList.selectedIdx = 0
            } else {
                mode = "menu"
                menuView.reset()
            }
            focusTimer.start()
        }
    }

    Timer {
        id:       focusTimer
        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }

    function toggle() { showing = !showing }

    // Functions for keybindings 
    function openScreenrecord() {
        showing = true
        mode = "menu"
        Qt.callLater(function() {
            menuView.reset()
            var tree = MenuData.buildTree()
            menuView.pushPage("Trigger", tree[2].children)
            menuView.pushPage("Capture", tree[2].children[0].children)
            menuView.pushPage("Screenrecord", tree[2].children[0].children[1].children)
        })
    }

    function openSystem() {
        showing = true
        mode = "menu"
        Qt.callLater(function() {
            menuView.reset()
            var tree = MenuData.buildTree()
            menuView.pushPage("System", tree[9].children)
        })
    }

}