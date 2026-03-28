import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "pages"

PanelWindow {
    id: root

    property var state: null
    property var theme: ({})
    property bool showing: false
    property int pageIndex: 0

    readonly property var pages: [
        { label: "General", desc: "Shell identity and window behavior" },
        { label: "Notifications", desc: "Toast position and test alert" },
        { label: "OSD", desc: "On-screen display position" },
        { label: "Bar", desc: "Style, position and shell layout" },
        { label: "About", desc: "Shell info and config location" }
    ]

    function t(key, fallback) { return theme[key] || fallback }

    function currentPageMeta() {
        return pages[pageIndex] || pages[0]
    }

    function setPage(index) {
        const clamped = Math.max(0, Math.min(index, pages.length - 1))
        pageIndex = clamped
    }

    property real cardX: 0
    property real cardY: 0
    property bool cardPositioned: false

    function centerCard() {
        if (!backdrop.width || !backdrop.height)
            return
        cardX = Math.round((backdrop.width - card.width) / 2)
        cardY = Math.round((backdrop.height - card.height) / 2)
        cardPositioned = true
    }

    function clampCard() {
        if (!backdrop.width || !backdrop.height)
            return
        cardX = Math.max(12, Math.min(cardX, backdrop.width - card.width - 12))
        cardY = Math.max(12, Math.min(cardY, backdrop.height - card.height - 12))
    }

    visible: showing || reveal > 0.001
    implicitWidth: 860
    implicitHeight: 520

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property real reveal: showing ? 1 : 0

    Behavior on reveal {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    onVisibleChanged: {
        if (visible)
            forceActiveFocus()
    }

    onShowingChanged: {
        if (showing) {
            if (state && state.openSettingsOnGeneralAlways)
                setPage(0)
            if (!state || !state.rememberSettingsWindowPosition || !cardPositioned)
                centerCard()
            else
                clampCard()
        }
    }

    Keys.onPressed: event => {
        if (!showing) return
        if (event.key === Qt.Key_Escape) {
            showing = false
            event.accepted = true
        }
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            id: backdropArea
            anchors.fill: parent
            onClicked: mouse => {
                const point = card.mapFromItem(backdropArea, mouse.x, mouse.y)
                const insideCard = point.x >= 0 && point.y >= 0
                    && point.x <= card.width && point.y <= card.height
                if (!insideCard)
                    root.showing = false
            }
        }

        Rectangle {
            id: card
            width: Math.min(parent.width - 48, 860)
            height: Math.min(parent.height - 48, 520)
            x: root.cardX
            y: root.cardY
            radius: 20
            color: Qt.darker(root.t("bg", "#0b100c"), 1.06)
            border.color: Qt.alpha(root.t("accent", "#9ccfa0"), 0.18)
            border.width: 1
            opacity: root.reveal
            scale: 0.985 + (0.015 * root.reveal)
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            onWidthChanged: {
                if (!root.cardPositioned)
                    root.centerCard()
                else
                    root.clampCard()
            }

            onHeightChanged: {
                if (!root.cardPositioned)
                    root.centerCard()
                else
                    root.clampCard()
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 14
                anchors.rightMargin: 14
                width: 30
                height: 30
                radius: 9
                color: Qt.alpha(root.t("dim", "#45475a"), 0.24)
                border.color: Qt.alpha(root.t("accent", "#9ccfa0"), 0.08)
                border.width: 1
                z: 20

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: root.t("fg", "#eef6ef")
                    font.pixelSize: 10
                    font.family: "JetBrains Mono"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showing = false
                }
            }

            MouseArea {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 14
                anchors.leftMargin: 14
                anchors.rightMargin: 52
                height: 40
                z: 15
                cursorShape: Qt.SizeAllCursor
                property real pressOffsetX: 0
                property real pressOffsetY: 0

                onPressed: mouse => {
                    pressOffsetX = mouse.x
                    pressOffsetY = mouse.y
                }

                onPositionChanged: mouse => {
                    if (!pressed)
                        return
                    root.cardX += mouse.x - pressOffsetX
                    root.cardY += mouse.y - pressOffsetY
                    root.cardPositioned = true
                    root.clampCard()
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    id: titleBar
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Anomshell Settings"
                            color: root.t("fg", "#eef6ef")
                            font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font Propo "
                            font.weight: Font.DemiBold
                            textFormat: Text.RichText
                        }

                        Text {
                            text: "Setting Manager for Anomshell."
                            color: Qt.alpha(root.t("muted", "#9fb29f"), 0.7)
                            font.pixelSize: 9
                            font.family: "JetBrains Mono"
                        }
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Rectangle {
                        z: 2
                        Layout.preferredWidth: 180
                        Layout.fillHeight: true
                        radius: 16
                        color: Qt.darker(root.t("bg", "#08100b"), 1.12)
                        border.color: Qt.alpha(root.t("accent", "#9ccfa0"), 0.1)
                        border.width: 1
                        clip: true

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Rectangle {
                                width: parent.width
                                height: 64
                                radius: 14
                                color: Qt.darker(root.t("bg", "#0f1511"), 1.02)
                                border.color: Qt.alpha(root.t("accent", "#9ccfa0"), 0.08)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 3

                                    Text {
                                        text: "QS"
                                        color: root.t("accent", "#9ccfa0")
                                        font.pixelSize: 18
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: "Local shell config"
                                        color: root.t("fg", "#eef6ef")
                                        font.pixelSize: 9
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        text: "Control panel"
                                        color: Qt.alpha(root.t("muted", "#9fb29f"), 0.65)
                                        font.pixelSize: 8
                                        font.family: "JetBrains Mono"
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 40
                                radius: 11
                                color: root.pageIndex === 0 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.18) : Qt.alpha(root.t("dim", "#45475a"), 0.16)
                                border.color: root.pageIndex === 0 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.34) : Qt.alpha(root.t("accent", "#9ccfa0"), 0.08)
                                border.width: 1

                                Rectangle {
                                    width: 3
                                    radius: 2
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: root.pageIndex === 0 ? 20 : 0
                                    color: root.t("accent", "#9ccfa0")
                                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: ""
                                        color: root.t("accent", "#9ccfa0")
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: root.pages[0].label
                                            color: root.pageIndex === 0 ? root.t("fg", "#eef6ef") : Qt.alpha(root.t("fg", "#eef6ef"), 0.8)
                                            font.pixelSize: 9
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: root.pages[0].desc
                                            color: Qt.alpha(root.t("muted", "#9fb29f"), 0.58)
                                            font.pixelSize: 7
                                            font.family: "JetBrains Mono"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setPage(0)
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 40
                                radius: 11
                                color: root.pageIndex === 1 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.18) : Qt.alpha(root.t("dim", "#45475a"), 0.16)
                                border.color: root.pageIndex === 1 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.34) : Qt.alpha(root.t("accent", "#9ccfa0"), 0.08)
                                border.width: 1

                                Rectangle {
                                    width: 3
                                    radius: 2
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: root.pageIndex === 1 ? 20 : 0
                                    color: root.t("accent", "#9ccfa0")
                                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: ""
                                        color: root.t("accent", "#9ccfa0")
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: root.pages[1].label
                                            color: root.pageIndex === 1 ? root.t("fg", "#eef6ef") : Qt.alpha(root.t("fg", "#eef6ef"), 0.8)
                                            font.pixelSize: 9
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: root.pages[1].desc
                                            color: Qt.alpha(root.t("muted", "#9fb29f"), 0.58)
                                            font.pixelSize: 7
                                            font.family: "JetBrains Mono"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setPage(1)
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 40
                                radius: 11
                                color: root.pageIndex === 2 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.18) : Qt.alpha(root.t("dim", "#45475a"), 0.16)
                                border.color: root.pageIndex === 2 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.34) : Qt.alpha(root.t("accent", "#9ccfa0"), 0.08)
                                border.width: 1

                                Rectangle {
                                    width: 3
                                    radius: 2
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: root.pageIndex === 2 ? 20 : 0
                                    color: root.t("accent", "#9ccfa0")
                                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: ""
                                        color: root.t("accent", "#9ccfa0")
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: root.pages[2].label
                                            color: root.pageIndex === 2 ? root.t("fg", "#eef6ef") : Qt.alpha(root.t("fg", "#eef6ef"), 0.8)
                                            font.pixelSize: 9
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: root.pages[2].desc
                                            color: Qt.alpha(root.t("muted", "#9fb29f"), 0.58)
                                            font.pixelSize: 7
                                            font.family: "JetBrains Mono"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setPage(2)
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 40
                                radius: 11
                                color: root.pageIndex === 3 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.18) : Qt.alpha(root.t("dim", "#45475a"), 0.16)
                                border.color: root.pageIndex === 3 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.34) : Qt.alpha(root.t("accent", "#9ccfa0"), 0.08)
                                border.width: 1

                                Rectangle {
                                    width: 3
                                    radius: 2
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: root.pageIndex === 3 ? 20 : 0
                                    color: root.t("accent", "#9ccfa0")
                                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: ""
                                        color: root.t("accent", "#9ccfa0")
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: root.pages[3].label
                                            color: root.pageIndex === 3 ? root.t("fg", "#eef6ef") : Qt.alpha(root.t("fg", "#eef6ef"), 0.8)
                                            font.pixelSize: 9
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: root.pages[3].desc
                                            color: Qt.alpha(root.t("muted", "#9fb29f"), 0.58)
                                            font.pixelSize: 7
                                            font.family: "JetBrains Mono"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setPage(3)
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 40
                                radius: 11
                                color: root.pageIndex === 4 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.18) : Qt.alpha(root.t("dim", "#45475a"), 0.16)
                                border.color: root.pageIndex === 4 ? Qt.alpha(root.t("accent", "#9ccfa0"), 0.34) : Qt.alpha(root.t("accent", "#9ccfa0"), 0.08)
                                border.width: 1

                                Rectangle {
                                    width: 3
                                    radius: 2
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: root.pageIndex === 4 ? 20 : 0
                                    color: root.t("accent", "#9ccfa0")
                                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: ""
                                        color: root.t("accent", "#9ccfa0")
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: root.pages[4].label
                                            color: root.pageIndex === 4 ? root.t("fg", "#eef6ef") : Qt.alpha(root.t("fg", "#eef6ef"), 0.8)
                                            font.pixelSize: 9
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: root.pages[4].desc
                                            color: Qt.alpha(root.t("muted", "#9fb29f"), 0.58)
                                            font.pixelSize: 7
                                            font.family: "JetBrains Mono"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setPage(4)
                                }
                            }
                        }
                    }

                    Rectangle {
                        z: 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: Qt.darker(root.t("bg", "#0b100c"), 1.03)
                        border.color: Qt.alpha(root.t("accent", "#9ccfa0"), 0.1)
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: root.currentPageMeta().label
                                        color: root.t("fg", "#eef6ef")
                                        font.pixelSize: 15
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: root.currentPageMeta().desc
                                        color: Qt.alpha(root.t("muted", "#9fb29f"), 0.68)
                                        font.pixelSize: 9
                                        font.family: "JetBrains Mono"
                                    }
                                }

                            }

                            StackLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.topMargin: 6
                                currentIndex: root.pageIndex

                                GeneralPage {
                                    state: root.state
                                    theme: root.theme
                                    settingsWindow: root
                                }

                                NotificationsPage {
                                    state: root.state
                                    theme: root.theme
                                }

                                OsdPage {
                                    state: root.state
                                    theme: root.theme
                                }

                                BarPage {
                                    state: root.state
                                    theme: root.theme
                                }

                                AboutPage {
                                    state: root.state
                                    theme: root.theme
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
