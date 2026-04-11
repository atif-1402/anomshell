import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root
    property var theme:      ({})
    property var trayWindow: null

    function _isDirectIconSource(icon) {
        const value = icon || ""
        return value.startsWith("/") ||
            value.startsWith("file:") ||
            value.startsWith("image:") ||
            value.startsWith("qrc:") ||
            value.startsWith("data:")
    }

    function _iconProviderSource(icon) {
        const value = icon || ""
        if (value === "")
            return ""
        if (_isDirectIconSource(value))
            return value
        return "image://icon/" + encodeURIComponent(value)
    }

    function _traySearchText(item) {
        return [
            item?.id || "",
            item?.title || "",
            item?.tooltipTitle || "",
            item?.tooltipDescription || "",
            item?.icon || ""
        ].join(" ").toLowerCase()
    }

    function _hasAny(text, values) {
        for (const value of values) {
            if (text.includes(value))
                return true
        }
        return false
    }

    function _customGlyph(item) {
        const text = _traySearchText(item)
        if (_hasAny(text, ["spotify"])) return ""
        if (_hasAny(text, ["discord", "vesktop"])) return ""
        if (_hasAny(text, ["telegram"])) return ""
        if (_hasAny(text, ["steam"])) return ""
        if (_hasAny(text, ["slack"])) return "󰒱"
        if (_hasAny(text, ["obs", "obsidian"])) return text.includes("obsidian") ? "󰎚" : "󰐾"
        if (_hasAny(text, ["dropbox"])) return "󰇣"
        if (_hasAny(text, ["github", "gitkraken"])) return "󰊤"
        if (_hasAny(text, ["signal"])) return "󰭹"
        if (_hasAny(text, ["whatsapp"])) return "󰖣"
        if (_hasAny(text, ["element", "matrix"])) return "󱘖"
        if (_hasAny(text, ["teams"])) return "󰊻"
        if (_hasAny(text, ["zoom"])) return "󰬡"
        if (_hasAny(text, ["chromium", "chrome", "brave", "firefox", "browser"])) return "󰖟"
        if (_hasAny(text, ["code", "vscode", "cursor", "zed"])) return "󰨞"
        if (_hasAny(text, ["thunderbird", "mail"])) return "󰇮"
        if (_hasAny(text, ["syncthing"])) return "󱂵"
        if (_hasAny(text, ["nextcloud"])) return "󰅟"
        if (_hasAny(text, ["tailscale"])) return "󰛳"
        if (_hasAny(text, ["vpn", "proton"])) return "󰦝"
        if (_hasAny(text, ["docker"])) return "󰡨"
        if (_hasAny(text, ["qbittorrent", "torrent", "transmission"])) return "󰃘"
        if (_hasAny(text, ["mpv", "vlc", "media player"])) return "󰐊"
        if (_hasAny(text, ["bluetooth", "blueberry", "blueman"])) return "󰂯"
        if (_hasAny(text, ["network", "wifi", "nm-applet"])) return "󰖩"
        if (_hasAny(text, ["volume", "audio", "pipewire", "pavucontrol"])) return "󰕾"
        if (_hasAny(text, ["battery", "power"])) return "󰁹"
        if (_hasAny(text, ["clipboard"])) return "󰅌"
        if (_hasAny(text, ["calendar"])) return "󰃭"
        if (_hasAny(text, ["notes", "note"])) return "󱞎"
        if (_hasAny(text, ["input method", "input-keyboard"])) return "󰧹"
        return ""
    }

    implicitWidth:  trayRow.implicitWidth
    implicitHeight: 28

    Row {
        id:      trayRow
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: SystemTray.items

            Item {
                id:     trayItem
                width:  18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                property bool hovered:     false
                property bool menuShowing: false

                QsMenuOpener {
                    id:   opener
                    menu: modelData.menu
                }

                // ── Menu PanelWindow ──────────────
                PanelWindow {
                    id:      menuWin
                    visible: trayItem.menuShowing

                    anchors { top: true; right: true }
                    margins { top: 38; right: 40 }

                    implicitWidth:  menuCol.implicitWidth + 16
                    implicitHeight: menuCol.implicitHeight + 16

                    color:         "transparent"
                    exclusiveZone: -1
                    WlrLayershell.layer:         WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    Rectangle {
                        anchors.fill: parent
                        radius:       10
                        color:        root.theme.bg  || "#1e1e2e"
                        border.color: root.theme.dim  || "#45475a"
                        border.width: 1
                        clip:         true

                        opacity: trayItem.menuShowing ? 1 : 0
                        scale:   trayItem.menuShowing ? 1 : 0.95
                        transformOrigin: Item.Bottom

                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        // click outside to close
                        MouseArea {
                            anchors.fill: parent
                            z:            -1
                            onClicked:    trayItem.menuShowing = false
                        }

                        Column {
                            id:             menuCol
                            anchors.left:   parent.left
                            anchors.top:    parent.top
                            anchors.margins: 8
                            spacing:        2

                            Repeater {
                                model: opener.children.values

                                delegate: Item {
                                    width:  menuLabel.implicitWidth + 24
                                    height: modelData.isSeparator ? 9 : 30

                                    Rectangle {
                                        visible:          modelData.isSeparator
                                        anchors.centerIn: parent
                                        width:            parent.width
                                        height:           1
                                        color:            root.theme.dim || "#45475a"
                                        opacity:          0.5
                                    }

                                    Rectangle {
                                        visible:      !modelData.isSeparator
                                        anchors.fill: parent
                                        radius:       6
                                        color:        entryMa.containsMouse
                                                      ? Qt.alpha(root.theme.accent || "#89b4fa", 0.15)
                                                      : "transparent"
                                        Behavior on color {
                                            ColorAnimation { duration: 100 }
                                        }

                                        Text {
                                            id:                     menuLabel
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left:           parent.left
                                            anchors.leftMargin:     10
                                            text:                   modelData.text || ""
                                            color:                  modelData.enabled
                                                                    ? (root.theme.fg    || "#cdd6f4")
                                                                    : (root.theme.muted || "#585b70")
                                            font.pixelSize:         11
                                            font.family:            "JetBrainsMono Nerd Font"
                                        }

                                        MouseArea {
                                            id:           entryMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape:  modelData.enabled
                                                          ? Qt.PointingHandCursor
                                                          : Qt.ArrowCursor
                                            onClicked: {
                                                if (modelData.enabled) {
                                                    modelData.triggered()
                                                    trayItem.menuShowing = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                IconImage {
                    id:               icon
                    anchors.centerIn: parent
                    width:            13
                    height:           13
                    implicitSize:     13
                    source:           root._iconProviderSource(modelData.icon)
                    asynchronous:     true
                    mipmap:           true
                    visible:          glyphIcon.text === ""

                    opacity: trayItem.hovered ? 1.0 : 0.6

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    implicitSize: 13
                    source: root._isDirectIconSource(modelData.icon) ? "" : (modelData.icon || "")
                    asynchronous: true
                    mipmap: true
                    visible: glyphIcon.text === "" && source !== "" && icon.status === Image.Error
                    opacity: icon.opacity

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                Text {
                    id: glyphIcon
                    anchors.centerIn: parent
                    text: root._customGlyph(modelData)
                    visible: text !== ""
                    color: trayItem.hovered
                        ? (root.theme.accent || "#89b4fa")
                        : (root.theme.fg || "#cdd6f4")
                    opacity: trayItem.hovered ? 1.0 : 0.68
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    visible: trayItem.hovered && !trayItem.menuShowing
                    opacity: trayItem.hovered && !trayItem.menuShowing ? 1 : 0
                    z:       99

                    width:  tooltipText.implicitWidth + 16
                    height: 22
                    radius: 6

                    anchors.bottom:           parent.top
                    anchors.bottomMargin:     6
                    anchors.horizontalCenter: parent.horizontalCenter

                    color:        root.theme.bg  || "#1e1e2e"
                    border.color: root.theme.dim  || "#45475a"
                    border.width: 1

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Text {
                        id:               tooltipText
                        anchors.centerIn: parent
                        text:             modelData.tooltipTitle !== ""
                                          ? modelData.tooltipTitle
                                          : modelData.title
                        color:            root.theme.fg || "#cdd6f4"
                        font.pixelSize:   10
                        font.family:      "JetBrainsMono Nerd Font"
                    }
                }

                MouseArea {
                    anchors.fill:    parent
                    hoverEnabled:    true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape:     Qt.PointingHandCursor

                    onEntered: trayItem.hovered = true
                    onExited:  trayItem.hovered = false

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.hasMenu)
                                trayItem.menuShowing = !trayItem.menuShowing
                        }
                    }
                }
            }
        }
    }
}
