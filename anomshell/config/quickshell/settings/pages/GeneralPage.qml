import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var state: null
    property var theme: ({})
    property var settingsWindow: null

    function t(key, fallback) { return theme[key] || fallback }

    function currentIcon() {
        return root.state ? root.state.launcherIconPreset : "omarchy"
    }

    function setIcon(key) {
        if (root.state)
            root.state.launcherIconPreset = key
    }

    function launcherIconSize() {
        return root.state ? root.state.launcherIconSize : 12
    }

    function setLauncherIconSize(size) {
        if (root.state)
            root.state.launcherIconSize = Math.max(10, Math.min(18, Math.round(size)))
    }

    function rememberWindowPosition() {
        return root.state ? root.state.rememberSettingsWindowPosition : true
    }

    function setRememberWindowPosition(enabled) {
        if (!root.state)
            return
        root.state.rememberSettingsWindowPosition = enabled
        if (!enabled && root.settingsWindow) {
            root.settingsWindow.centerCard()
            root.settingsWindow.cardPositioned = false
        }
    }

    function openOnGeneralAlways() {
        return root.state ? root.state.openSettingsOnGeneralAlways : false
    }

    function setOpenOnGeneralAlways(enabled) {
        if (root.state)
            root.state.openSettingsOnGeneralAlways = enabled
    }

    function currentWorkspaceStyle() {
        return root.state ? root.state.workspaceStyle : "og"
    }

    function setWorkspaceStyle(style) {
        if (root.state)
            root.state.workspaceStyle = style
    }

    readonly property var iconSizeOptions: [
        { value: 10, label: "Small", desc: "Tighter launcher mark." },
        { value: 12, label: "Default", desc: "Balanced with the bar text." },
        { value: 14, label: "Large", desc: "More visible in the left cluster." }
    ]

    readonly property var workspaceStyleOptions: [
        { key: "og", label: "OG", preview: "IV", desc: "Roman numerals with the original underline feel." },
        { key: "strip", label: "Omarchy", preview: "4", desc: "Number row with the active workspace shown as a clean block." },
        { key: "pulse", label: "Pulse", preview: "•", desc: "Minimal dots and capsules with a soft glow." }
    ]

    readonly property var iconOptions: [
        { key: "omarchy", label: "Omarchy", preview: "\ue900", family: "Omarchy", desc: "Use the original Omarchy mark." },
        { key: "arch", label: "Arch", preview: "", family: "JetBrainsMono Nerd Font Propo", desc: "Use the Arch Linux icon." },
        { key: "hyprland", label: "Hyprland", preview: "", family: "JetBrainsMono Nerd Font Propo", desc: "Use the Hyprland glyph." },
        { key: "nix", label: "Tux", preview: "", family: "JetBrainsMono Nerd Font Propo", desc: "Use the Classic Linux Tux." },
        { key: "command", label: "Command", preview: "󰘳", family: "JetBrainsMono Nerd Font Propo", desc: "Use the Classic Mac Command icon." },
        { key: "windows", label: "Windows", preview: "󰖳", family: "JetBrainsMono Nerd Font Propo", desc: "Use the Windows icon." }
    ]

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight

        Column {
            id: contentColumn
            width: root.width
            spacing: 10

            Rectangle {
                width: parent.width
                radius: 16
                color: Qt.darker(t("bg", "#0b100c"), 1.04)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.1)
                border.width: 1
                implicitHeight: 48 + (root.iconOptions.length * 42) + ((root.iconOptions.length - 1) * 8)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Launcher icon"
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                    }

                    Repeater {
                        model: root.iconOptions

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 10
                            color: root.currentIcon() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                                : Qt.alpha(t("dim", "#45475a"), 0.14)
                            border.color: root.currentIcon() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                                : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.preview
                                    color: root.currentIcon() === modelData.key ? t("accent", "#9ccfa0") : Qt.alpha(t("fg", "#eef6ef"), 0.72)
                                    font.pixelSize: 13
                                    font.family: modelData.family
                                    font.weight: Font.DemiBold
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.label
                                        color: t("fg", "#eef6ef")
                                        font.pixelSize: 9
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.desc
                                        color: Qt.alpha(t("muted", "#9fb29f"), 0.58)
                                        font.pixelSize: 7
                                        font.family: "JetBrains Mono"
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setIcon(modelData.key)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                radius: 16
                color: Qt.darker(t("bg", "#0b100c"), 1.04)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.1)
                border.width: 1
                implicitHeight: 48 + (root.workspaceStyleOptions.length * 42) + ((root.workspaceStyleOptions.length - 1) * 8)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Workspace style"
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                    }

                    Repeater {
                        model: root.workspaceStyleOptions

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 10
                            color: root.currentWorkspaceStyle() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                                : Qt.alpha(t("dim", "#45475a"), 0.14)
                            border.color: root.currentWorkspaceStyle() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                                : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 18
                                    radius: 8
                                    color: root.currentWorkspaceStyle() === modelData.key
                                        ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                                        : Qt.alpha(t("fg", "#eef6ef"), 0.05)
                                    border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.14)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.preview
                                        color: root.currentWorkspaceStyle() === modelData.key
                                            ? t("accent", "#9ccfa0")
                                            : Qt.alpha(t("fg", "#eef6ef"), 0.68)
                                        font.pixelSize: modelData.key === "pulse" ? 12 : 8
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.label
                                        color: t("fg", "#eef6ef")
                                        font.pixelSize: 9
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.desc
                                        color: Qt.alpha(t("muted", "#9fb29f"), 0.58)
                                        font.pixelSize: 7
                                        font.family: "JetBrains Mono"
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setWorkspaceStyle(modelData.key)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                radius: 16
                color: Qt.darker(t("bg", "#0b100c"), 1.04)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.1)
                border.width: 1
                implicitHeight: 48 + (root.iconSizeOptions.length * 42) + ((root.iconSizeOptions.length - 1) * 8)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Launcher icon size"
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                    }

                    Repeater {
                        model: root.iconSizeOptions

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 10
                            color: root.launcherIconSize() === modelData.value
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                                : Qt.alpha(t("dim", "#45475a"), 0.14)
                            border.color: root.launcherIconSize() === modelData.value
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                                : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: "A"
                                    color: root.launcherIconSize() === modelData.value ? t("accent", "#9ccfa0") : Qt.alpha(t("fg", "#eef6ef"), 0.72)
                                    font.pixelSize: modelData.value
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.DemiBold
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.label
                                        color: t("fg", "#eef6ef")
                                        font.pixelSize: 9
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.desc
                                        color: Qt.alpha(t("muted", "#9fb29f"), 0.58)
                                        font.pixelSize: 7
                                        font.family: "JetBrains Mono"
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: modelData.value + "px"
                                    color: Qt.alpha(t("muted", "#9fb29f"), 0.72)
                                    font.pixelSize: 8
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setLauncherIconSize(modelData.value)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                radius: 16
                color: Qt.darker(t("bg", "#0b100c"), 1.04)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.1)
                border.width: 1
                implicitHeight: 168

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Window behavior"
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 10
                        color: root.rememberWindowPosition()
                            ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                            : Qt.alpha(t("dim", "#45475a"), 0.14)
                        border.color: root.rememberWindowPosition()
                            ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                            : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: root.rememberWindowPosition() ? "On" : "Off"
                                color: t("accent", "#9ccfa0")
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Remember window position"
                                    color: t("fg", "#eef6ef")
                                    font.pixelSize: 9
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Keep the dragged settings window where you left it."
                                    color: Qt.alpha(t("muted", "#9fb29f"), 0.58)
                                    font.pixelSize: 7
                                    font.family: "JetBrains Mono"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setRememberWindowPosition(!root.rememberWindowPosition())
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 10
                        color: root.openOnGeneralAlways()
                            ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                            : Qt.alpha(t("dim", "#45475a"), 0.14)
                        border.color: root.openOnGeneralAlways()
                            ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                            : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: root.openOnGeneralAlways() ? "On" : "Off"
                                color: t("accent", "#9ccfa0")
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Open settings on General tab always"
                                    color: t("fg", "#eef6ef")
                                    font.pixelSize: 9
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Always start on General instead of the last tab you used."
                                    color: Qt.alpha(t("muted", "#9fb29f"), 0.58)
                                    font.pixelSize: 7
                                    font.family: "JetBrains Mono"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setOpenOnGeneralAlways(!root.openOnGeneralAlways())
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 10
                            color: Qt.alpha(t("dim", "#45475a"), 0.16)
                            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Center Window Now"
                                color: Qt.alpha(t("fg", "#eef6ef"), 0.8)
                                font.pixelSize: 9
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.settingsWindow)
                                        return
                                    root.settingsWindow.centerCard()
                                    root.settingsWindow.cardPositioned = root.rememberWindowPosition()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
