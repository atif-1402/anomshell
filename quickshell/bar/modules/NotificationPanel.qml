import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Item {
    id: root
    property var theme: ({})

    function t(key, fallback) { return theme[key] || fallback }

    function appIcon(name) {
        const map = {
            "firefox": "󰈹", "chromium": "󰊯", "discord": "󰙯",
            "spotify": "󰓇", "telegram": "󰔁", "code": "󰨞",
            "vscode": "󰨞", "alacritty": "󰆍", "kitty": "󰆍",
            "steam": "󰓓", "vlc": "󰕼", "mpv": "󰎁",
            "thunar": "󰉋", "nautilus": "󰉋",
        }
        const k = (name || "").toLowerCase()
        for (const [key, val] of Object.entries(map))
            if (k.includes(key)) return val
        return "󰂚"
    }

    Timer {
        id: autoDismissTimer
        interval: 3000
        repeat: false
        running: false
        onTriggered: {
            if (toastWin.latest)
                notifServer.hideToast(toastWin.latest.id)
        }
    }

    Timer {
        id: hideDelayTimer
        interval: 300
        repeat: false
        onTriggered: toastWin.reallyVisible = false
    }

    // ── HUD Toast ──────────────────────────────────────────────────────────
    WlrLayershell {
        id: toastWin

        property bool reallyVisible: false
        visible: !notifServer.panelOpen && reallyVisible

        color: "transparent"
        anchors.top: true

        // FIX A: shrink window to toast width only — not Screen.width.
        // Screen.width was creating a full-width invisible surface that
        // blocked the bar and every other shell element beneath it.
        implicitWidth: hudBg.width > 0 ? hudBg.width : 400
        implicitHeight: 44 + collapsedH + (hasActions ? expandedExtra : 0) + 10

        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        namespace: "notif-toast"

        property var visibleToasts: notifServer.notifications.filter(
            n => !notifServer.hiddenToasts.includes(n.id)
        )
        property var latest: visibleToasts.length > 0 ? visibleToasts[0] : null
        property bool hasActions: latest && latest.actions && latest.actions.length > 0

        readonly property real collapsedH: mainRow.implicitHeight + 18
        readonly property real expandedExtra: actionRow.implicitHeight + 16

        // FIX B: isHovered now driven by HoverHandler inside hudBg,
        // not by a sibling MouseArea. HoverHandler does NOT consume click
        // events so action buttons and the X button receive clicks normally.
        property bool isHovered: false

        onVisibleToastsChanged: {
            if (visibleToasts.length > 0) {
                reallyVisible = true
                hideDelayTimer.stop()
            } else {
                hideDelayTimer.restart()
            }
        }

        // ── visual toast ──────────────────────────────────────────────────
        Rectangle {
            id: hudBg
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 44

            width: mainRow.implicitWidth + 32

            height: toastWin.isHovered && toastWin.hasActions
                ? toastWin.collapsedH + toastWin.expandedExtra
                : toastWin.collapsedH

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
            }

            radius: 14
            color: t("bg", "#1e1e2e")
            border.color: Qt.rgba(1,1,1,0.07)
            border.width: 1
            clip: true
            opacity: 0
            scale: 0.92

            // FIX B: HoverHandler tracks hover without consuming any mouse
            // events — clicks fall through to child MouseAreas normally.
            HoverHandler {
                id: toastHover
                onHoveredChanged: {
                    toastWin.isHovered = hovered
                    if (hovered) {
                        autoDismissTimer.stop()
                    } else {
                        autoDismissTimer.restart()
                    }
                }
            }

            // Right-click dismiss via TapHandler — also non-blocking to children
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    if (toastWin.latest)
                        notifServer.hideToast(toastWin.latest.id)
                }
            }

            Connections {
                target: toastWin
                function onLatestChanged() {
                    if (toastWin.latest) {
                        toastWin.isHovered = false
                        hudBg.opacity = 0
                        hudBg.scale = 0.92
                        hudIn.restart()
                        autoDismissTimer.restart()
                    } else {
                        hudOut.restart()
                    }
                }
            }

            ParallelAnimation {
                id: hudIn
                NumberAnimation { target: hudBg; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: hudBg; property: "scale"; to: 1; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 0.3 }
            }

            ParallelAnimation {
                id: hudOut
                NumberAnimation { target: hudBg; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
                NumberAnimation { target: hudBg; property: "scale"; to: 0.92; duration: 200; easing.type: Easing.InCubic }
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 9
                spacing: 8

                RowLayout {
                    id: mainRow
                    spacing: 8

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: toastWin.latest && notifServer.isCritical(toastWin.latest)
                            ? t("red", "#f38ba8")
                            : t("accent", "#89b4fa")
                    }

                    Text {
                        text: toastWin.latest ? (toastWin.latest.appName || "") : ""
                        color: Qt.rgba(1,1,1,0.38)
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                    }

                    Rectangle { width: 1; height: 10; color: Qt.rgba(1,1,1,0.12) }

                    Text {
                        text: toastWin.latest ? (toastWin.latest.summary || "") : ""
                        color: t("fg", "#cdd6f4")
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.family: "JetBrains Mono"
                        elide: Text.ElideRight
                        Layout.maximumWidth: 300
                    }

                    Rectangle {
                        visible: toastWin.visibleToasts.length > 1
                        width: moreTxt.implicitWidth + 10
                        height: 18; radius: 9
                        color: Qt.rgba(1,1,1,0.07)
                        Text {
                            id: moreTxt
                            anchors.centerIn: parent
                            text: "+" + (toastWin.visibleToasts.length - 1)
                            color: Qt.rgba(1,1,1,0.35)
                            font.pixelSize: 10
                            font.family: "JetBrains Mono"
                        }
                    }

                    Text {
                        text: "✕"
                        font.pixelSize: 9
                        color: xhov.containsMouse ? t("fg", "#cdd6f4") : Qt.rgba(1,1,1,0.2)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        MouseArea {
                            id: xhov
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (toastWin.latest)
                                    notifServer.hideToast(toastWin.latest.id)
                            }
                        }
                    }
                }

                Row {
                    id: actionRow
                    visible: toastWin.hasActions
                    opacity: toastWin.isHovered ? 1 : 0
                    spacing: 6
                    Layout.alignment: Qt.AlignHCenter

                    Behavior on opacity {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        model: toastWin.latest && toastWin.latest.actions
                            ? toastWin.latest.actions : []
                        delegate: Rectangle {
                            required property var modelData
                            width: hudActLbl.implicitWidth + 16
                            height: 24
                            radius: 6
                            color: hudActMa.containsMouse
                                ? t("accent", "#89b4fa")
                                : Qt.rgba(1,1,1,0.07)
                            border.color: hudActMa.containsMouse
                                ? "transparent" : Qt.rgba(1,1,1,0.1)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 80 } }
                            Text {
                                id: hudActLbl
                                anchors.centerIn: parent
                                text: modelData.text
                                color: hudActMa.containsMouse
                                    ? t("bg", "#1e1e2e") : t("fg", "#cdd6f4")
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            MouseArea {
                                id: hudActMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Panel ──────────────────────────────────────────────────────────────
    WlrLayershell {
        id: panelWin
        visible: notifServer.panelOpen
        color: "transparent"
        anchors.right: true
        anchors.top: true
        implicitWidth: 380
        implicitHeight: 640
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        namespace: "notif-panel"

        MouseArea {
            anchors.fill: parent
            onClicked: notifServer.panelOpen = false
            z: -1
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 44
            anchors.rightMargin: 12
            width: 360
            height: 570
            radius: 14
            color: t("bg", "#1e1e2e")
            border.color: Qt.rgba(1,1,1,0.06)
            border.width: 1

            opacity: notifServer.panelOpen ? 1 : 0
            x: notifServer.panelOpen ? 0 : 16
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Notifications"
                        color: t("fg", "#cdd6f4")
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.family: "JetBrains Mono"
                    }

                    Rectangle {
                        visible: notifServer.notifications.length > 0
                        width: Math.max(22, cntTxt.implicitWidth + 10)
                        height: 20
                        radius: 10
                        color: Qt.rgba(
                            parseInt(t("accent","#89b4fa").slice(1,3),16)/255,
                            parseInt(t("accent","#89b4fa").slice(3,5),16)/255,
                            parseInt(t("accent","#89b4fa").slice(5,7),16)/255,
                            0.12
                        )
                        Text {
                            id: cntTxt
                            anchors.centerIn: parent
                            text: notifServer.notifications.length
                            color: t("accent", "#89b4fa")
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.family: "JetBrains Mono"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: notifServer.notifications.length > 0
                        text: "clear all"
                        color: clrHov.containsMouse
                            ? t("red", "#f38ba8") : Qt.rgba(1,1,1,0.25)
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        MouseArea {
                            id: clrHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notifServer.clearAll()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1,1,1,0.05)
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: pList.implicitHeight
                    clip: true

                    Column {
                        id: pList
                        width: parent.width
                        spacing: 5

                        Repeater {
                            model: notifServer.notifications
                            delegate: Rectangle {
                                required property var modelData
                                width: pList.width
                                height: pInner.implicitHeight + 18
                                radius: 10
                                color: phov.containsMouse
                                    ? Qt.rgba(1,1,1,0.04) : Qt.rgba(1,1,1,0.02)
                                border.color: Qt.rgba(1,1,1,0.04)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 80 } }

                                MouseArea {
                                    id: phov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.RightButton
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton)
                                            notifServer.dismiss(modelData)
                                    }
                                }

                                ColumnLayout {
                                    id: pInner
                                    anchors {
                                        left: parent.left; right: parent.right
                                        top: parent.top
                                        margins: 12; topMargin: 10
                                    }
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 7

                                        Rectangle {
                                            width: 6; height: 6; radius: 3
                                            color: notifServer.isCritical(modelData)
                                                ? t("red", "#f38ba8") : t("accent", "#89b4fa")
                                            opacity: 0.85
                                        }

                                        Text {
                                            text: modelData.appName
                                            color: Qt.rgba(1,1,1,0.3)
                                            font.pixelSize: 10
                                            font.family: "JetBrains Mono"
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "✕"
                                            font.pixelSize: 9
                                            color: dxhov.containsMouse
                                                ? t("red", "#f38ba8") : Qt.rgba(1,1,1,0.18)
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                            MouseArea {
                                                id: dxhov
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: notifServer.dismiss(modelData)
                                            }
                                        }
                                    }

                                    Text {
                                        visible: (modelData.summary || "") !== ""
                                        Layout.fillWidth: true
                                        text: modelData.summary || ""
                                        color: t("fg", "#cdd6f4")
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        font.family: "JetBrains Mono"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: (modelData.body || "").trim() !== ""
                                            && modelData.body !== modelData.summary
                                        Layout.fillWidth: true
                                        text: modelData.body || ""
                                        color: Qt.rgba(1,1,1,0.38)
                                        font.pixelSize: 11
                                        font.family: "JetBrains Mono"
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        spacing: 6
                                        visible: modelData.actions && modelData.actions.length > 0
                                        Repeater {
                                            model: modelData.actions
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: pALbl.implicitWidth + 16
                                                height: 22
                                                radius: 5
                                                color: pAMa.containsMouse
                                                    ? t("accent", "#89b4fa") : Qt.rgba(1,1,1,0.06)
                                                border.color: Qt.rgba(1,1,1,0.08)
                                                border.width: 1
                                                Behavior on color { ColorAnimation { duration: 80 } }
                                                Text {
                                                    id: pALbl
                                                    anchors.centerIn: parent
                                                    text: modelData.text
                                                    color: pAMa.containsMouse
                                                        ? t("bg", "#1e1e2e") : t("fg", "#cdd6f4")
                                                    font.pixelSize: 10
                                                    font.family: "JetBrains Mono"
                                                    Behavior on color { ColorAnimation { duration: 80 } }
                                                }
                                                MouseArea {
                                                    id: pAMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: modelData.invoke()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    visible: notifServer.notifications.length === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂛"
                            color: t("muted", "#585b70")
                            font.pixelSize: 30
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: 0.5
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "no notifications"
                            color: t("muted", "#585b70")
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            opacity: 0.5
                        }
                    }
                }
            }
        }
    }
}
