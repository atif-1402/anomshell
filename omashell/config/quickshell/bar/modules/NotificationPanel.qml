import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Item {
    id: root
    property var theme: ({})
    property var settings: null
    property string appFilter: ""
    property bool groupedView: true
    property var flatNotifications: notifServer ? notifServer.notificationsForApp(appFilter) : []
    property var groupedNotifications: notifServer ? notifServer.groupedNotifications(appFilter) : []
    property var panelModel: groupedView ? groupedNotifications : flatNotifications

    readonly property string dockPosition: settings && settings.notificationPosition
        ? settings.notificationPosition
        : "top-center"
    readonly property bool dockTop: dockPosition.indexOf("top") === 0
    readonly property bool dockBottom: dockPosition.indexOf("bottom") === 0
    readonly property bool dockLeft: dockPosition.indexOf("left") >= 0
    readonly property bool dockRight: dockPosition.indexOf("right") >= 0
    readonly property bool dockCenter: dockPosition.indexOf("center") >= 0

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
            const ids = toastWin.visibleToasts.map(n => n.id)
            if (ids.length > 0)
                notifServer.hideToasts(ids)
        }
    }

    // ── HUD Toast ──────────────────────────────────────────────────────────
    WlrLayershell {
        id: toastWin

        visible: !notifServer.panelOpen && visibleToasts.length > 0

        color: "transparent"
        anchors {
            top: dockTop
            bottom: dockBottom
            left: true
            right: true
        }

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

        onVisibleChanged: {
            if (!visible) {
                isHovered = false
                autoDismissTimer.stop()
            }
        }

        // ── visual toast ──────────────────────────────────────────────────
        Rectangle {
            id: hudBg
            x: dockCenter
                ? (parent.width - width) / 2
                : (dockRight ? parent.width - width - 10 : 10)
            y: dockBottom
                ? parent.height - height - 44
                : 44

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
    PanelWindow {
        id: panelWin
        visible: notifServer.panelOpen
        color: "transparent"

        anchors { top: true; right: true }
        margins { top: 44; right: 10 }

        implicitWidth: 284
        implicitHeight: Math.min(460, panelWin.screen.height - 58)

        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: t("bg", "#1e1e2e")
            border.color: t("dim", "#45475a")
            border.width: 1
            clip: true

            opacity: notifServer.panelOpen ? 1 : 0
            x: notifServer.panelOpen ? 0 : 16
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: panelCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 9
                    color: Qt.alpha(t("dim", "#45475a"), 0.30)
                    border.color: Qt.alpha(t("dim", "#45475a"), 0.50)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "Notifications"
                            color: t("fg", "#cdd6f4")
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.family: "JetBrains Mono"
                        }

                        Rectangle {
                            visible: notifServer.notifications.length > 0
                            width: Math.max(20, cntTxt.implicitWidth + 8)
                            height: 17
                            radius: 9
                            color: Qt.alpha(t("accent","#89b4fa"), 0.16)
                            Text {
                                id: cntTxt
                                anchors.centerIn: parent
                                text: notifServer.notifications.length
                                color: t("accent", "#89b4fa")
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                font.family: "JetBrains Mono"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: grpLbl.implicitWidth + 16
                            height: 20
                            radius: 10
                            color: grpHov.containsMouse || root.groupedView
                                ? Qt.alpha(t("accent", "#89b4fa"), 0.16)
                                : Qt.alpha(t("dim", "#45475a"), 0.42)
                            border.color: grpHov.containsMouse || root.groupedView
                                ? Qt.alpha(t("accent", "#89b4fa"), 0.38)
                                : Qt.alpha(t("dim", "#45475a"), 0.55)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            Text {
                                id: grpLbl
                                anchors.centerIn: parent
                                text: root.groupedView ? "grouped" : "flat"
                                color: grpHov.containsMouse || root.groupedView
                                    ? t("accent", "#89b4fa")
                                    : Qt.alpha(t("fg", "#cdd6f4"), 0.70)
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                            }

                            MouseArea {
                                id: grpHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.groupedView = !root.groupedView
                            }
                        }

                        Rectangle {
                            visible: notifServer.notifications.length > 0
                            width: clearLbl.implicitWidth + 14
                            height: 20
                            radius: 10
                            color: clrHov.containsMouse
                                ? Qt.alpha(t("red", "#f38ba8"), 0.18)
                                : Qt.alpha(t("dim", "#45475a"), 0.42)
                            border.color: clrHov.containsMouse
                                ? Qt.alpha(t("red", "#f38ba8"), 0.38)
                                : Qt.alpha(t("dim", "#45475a"), 0.55)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            Text {
                                id: clearLbl
                                anchors.centerIn: parent
                                text: "clear all"
                                color: clrHov.containsMouse
                                    ? t("red", "#f38ba8")
                                    : Qt.alpha(t("fg", "#cdd6f4"), 0.70)
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            MouseArea {
                                id: clrHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notifServer.clearAll()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(t("dim", "#45475a"), 0.50)
                }

                Flickable {
                    Layout.fillWidth: true
                    implicitHeight: notifServer.appNames().length > 0 ? 24 : 0
                    contentWidth: filterRow.implicitWidth
                    contentHeight: 24
                    clip: true
                    visible: notifServer.appNames().length > 0

                    Row {
                        id: filterRow
                        spacing: 6

                        Repeater {
                            model: ["All", ...notifServer.appNames()]
                            delegate: Rectangle {
                                required property var modelData
                                property bool active: (modelData === "All" && root.appFilter === "")
                                    || root.appFilter === modelData
                                width: chipLabel.implicitWidth + 14
                                height: 22
                                radius: 11
                                color: active
                                    ? Qt.alpha(t("accent", "#89b4fa"), 0.18)
                                    : Qt.alpha(t("dim", "#45475a"), 0.25)
                                border.color: active
                                    ? Qt.alpha(t("accent", "#89b4fa"), 0.42)
                                    : Qt.alpha(t("dim", "#45475a"), 0.4)
                                border.width: 1

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: active ? t("accent", "#89b4fa") : Qt.alpha(t("fg", "#cdd6f4"), 0.72)
                                    font.pixelSize: 8
                                    font.family: "JetBrains Mono"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.appFilter = modelData === "All" ? "" : modelData
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: notifList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                    model: root.panelModel

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                property: "y"
                                from: 12
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                to: 0
                                duration: 180
                                easing.type: Easing.InOutCubic
                            }
                        }
                    }

                    addDisplaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: 240
                            easing.type: Easing.InOutCubic
                        }
                    }

                    removeDisplaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: 240
                            easing.type: Easing.InOutCubic
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: 240
                            easing.type: Easing.InOutCubic
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isGroup: !!modelData.items
                        readonly property var latest: isGroup ? modelData.latest : modelData
                        readonly property var entryItems: isGroup ? modelData.items : [modelData]
                        property real slide: 0
                        property real slideLimit: Math.min(140, width * 0.45)
                        property bool dismissing: false
                        property real cardHeight: pInner.implicitHeight + 18
                        width: ListView.view.width
                        height: cardHeight
                        x: slide
                        opacity: 1 - Math.min(0.35, Math.abs(slide) / (width * 1.8))
                        radius: 10
                        clip: true
                        color: phov.containsMouse
                            ? Qt.rgba(1,1,1,0.04) : Qt.rgba(1,1,1,0.02)
                        border.color: Qt.rgba(1,1,1,0.04)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on slide {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        function commitDismiss(dir) {
                            if (dismissing) return
                            dismissing = true
                            slideDrag.enabled = false
                            slide = dir >= 0 ? slideLimit : -slideLimit
                            cardHeight = 0
                            dismissTimer.restart()
                        }

                        Timer {
                            id: dismissTimer
                            interval: 180
                            repeat: false
                            onTriggered: {
                                if (isGroup) notifServer.dismissMany(entryItems)
                                else notifServer.dismiss(modelData)
                            }
                        }

                        MouseArea {
                            id: phov
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    commitDismiss(-1)
                            }
                        }

                        DragHandler {
                            id: slideDrag
                            target: null
                            yAxis.enabled: false
                            xAxis.minimum: -parent.slideLimit
                            xAxis.maximum: parent.slideLimit

                            onTranslationChanged: {
                                parent.slide = Math.max(
                                    -parent.slideLimit,
                                    Math.min(parent.slideLimit, translation.x)
                                )
                            }

                            onActiveChanged: {
                                if (!active) {
                                    if (Math.abs(parent.slide) > parent.slideLimit * 0.58) {
                                        parent.commitDismiss(parent.slide)
                                    } else {
                                        parent.slide = 0
                                    }
                                }
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
                                    color: notifServer.isCritical(latest)
                                        ? t("red", "#f38ba8") : t("accent", "#89b4fa")
                                    opacity: 0.85
                                }

                                Text {
                                    text: latest.appName
                                    color: Qt.rgba(1,1,1,0.3)
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: isGroup && modelData.count > 1
                                    width: grpCnt.implicitWidth + 10
                                    height: 17
                                    radius: 9
                                    color: Qt.alpha(t("accent","#89b4fa"), 0.14)
                                    Text {
                                        id: grpCnt
                                        anchors.centerIn: parent
                                        text: modelData.count
                                        color: t("accent", "#89b4fa")
                                        font.pixelSize: 8
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                    }
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
                                                onClicked: commitDismiss(-1)
                                            }
                                        }
                                    }

                            Text {
                                visible: (latest.summary || "") !== ""
                                Layout.fillWidth: true
                                text: latest.summary || ""
                                color: t("fg", "#cdd6f4")
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                font.family: "JetBrains Mono"
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: (latest.body || "").trim() !== ""
                                    && latest.body !== latest.summary
                                Layout.fillWidth: true
                                text: latest.body || ""
                                color: Qt.rgba(1,1,1,0.38)
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: isGroup && modelData.count > 1
                                Layout.fillWidth: true
                                text: "Collapsed " + modelData.count + " notifications from " + latest.appName
                                color: Qt.alpha(t("fg", "#cdd6f4"), 0.44)
                                font.pixelSize: 9
                                font.family: "JetBrains Mono"
                                elide: Text.ElideRight
                            }

                            Row {
                                spacing: 6
                                visible: latest.actions && latest.actions.length > 0
                                Repeater {
                                    model: latest.actions
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

                Item {
                    visible: root.panelModel.length === 0
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
                            text: root.appFilter !== "" ? "no notifications for filter" : "no notifications"
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
