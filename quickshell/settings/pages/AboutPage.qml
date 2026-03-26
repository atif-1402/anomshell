import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property var state: null
    property var theme: ({})
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configDir: homeDir + "/.config/quickshell"

    function t(key, fallback) { return theme[key] || fallback }
    function shellQuote(value) {
        if (value === undefined || value === null)
            return "''"
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function openPath(path) {
        Quickshell.execDetached(["bash", "-lc",
            "if command -v xdg-open >/dev/null 2>&1; then " +
            "  xdg-open " + shellQuote(path) + " >/dev/null 2>&1; " +
            "fi"
        ])
    }

    function openEditorPath(path) {
        Quickshell.execDetached(["bash", "-lc",
            "FILE=" + shellQuote(path) + "; " +
            "if command -v omarchy-launch-editor >/dev/null 2>&1; then " +
            "  omarchy-launch-editor \"$FILE\"; " +
            "elif [ -n \"$EDITOR\" ] && command -v \"${EDITOR%% *}\" >/dev/null 2>&1 && command -v xdg-terminal-exec >/dev/null 2>&1; then " +
            "  setsid xdg-terminal-exec sh -lc '\"$EDITOR\" \"$1\"' sh \"$FILE\" >/dev/null 2>&1 & " +
            "elif command -v xdg-open >/dev/null 2>&1; then " +
            "  xdg-open \"$FILE\" >/dev/null 2>&1; " +
            "fi"
        ])
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight

        Column {
            id: contentColumn
            width: root.width
            spacing: 10

            Item {
                width: 1
                height: 10
            }

            Rectangle {
                width: parent.width - 8
                x: 4
                radius: 18
                color: Qt.darker(t("bg", "#0b100c"), 1.02)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.14)
                border.width: 1
                implicitHeight: 144
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 10
                            color: Qt.alpha(t("accent", "#9ccfa0"), 0.16)
                            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.22)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "QS"
                                color: t("accent", "#9ccfa0")
                                font.pixelSize: 13
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "Omarchy Shell"
                                color: t("fg", "#eef6ef")
                                font.pixelSize: 14
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "A custom Quickshell setup tuned for Omarchy workflows."
                                color: Qt.alpha(t("muted", "#9fb29f"), 0.74)
                                font.pixelSize: 9
                                font.family: "JetBrains Mono"
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 54
                            Layout.preferredHeight: 22
                            radius: 11
                            color: Qt.alpha(t("accent", "#9ccfa0"), 0.14)
                            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.2)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "MIT"
                                color: t("accent", "#9ccfa0")
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Launcher, themed settings, media OSD, notifications, bar layouts, tray handling, and shell controls in one compact config."
                        color: Qt.alpha(t("fg", "#eef6ef"), 0.82)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 9
                            color: Qt.alpha(t("fg", "#eef6ef"), 0.04)
                            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Bar: " + (root.state ? root.state.barStyle : "dock")
                                color: Qt.alpha(t("fg", "#eef6ef"), 0.84)
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 9
                            color: Qt.alpha(t("fg", "#eef6ef"), 0.04)
                            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Workspaces: " + (root.state ? root.state.workspaceStyle : "og")
                                color: Qt.alpha(t("fg", "#eef6ef"), 0.84)
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 9
                            color: Qt.alpha(t("fg", "#eef6ef"), 0.04)
                            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "OSD: " + (root.state ? root.state.osdPosition : "bottom-center")
                                color: Qt.alpha(t("fg", "#eef6ef"), 0.84)
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 8
                x: 4
                radius: 16
                color: Qt.darker(t("bg", "#0b100c"), 1.04)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.1)
                border.width: 1
                implicitHeight: 134

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Config Root"
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                    }

                    Text {
                        text: root.configDir
                        color: t("fg", "#eef6ef")
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Notification position: " + (root.state ? root.state.notificationPosition : "top-center")
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.72)
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                    }

                    Text {
                        text: "Bar position: " + (root.state ? root.state.barPosition : "top")
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.72)
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                    }

                    Text {
                        text: "Launcher icon: " + (root.state ? root.state.launcherIconPreset : "omarchy")
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.72)
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                    }
                }
            }

            Rectangle {
                width: parent.width - 8
                x: 4
                radius: 16
                color: Qt.darker(t("bg", "#0b100c"), 1.04)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.1)
                border.width: 1
                implicitHeight: mitTitle.implicitHeight + mitBody.implicitHeight + 42

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        id: mitTitle
                        text: "MIT License"
                        color: t("fg", "#eef6ef")
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                    }

                    Text {
                        id: mitBody
                        Layout.fillWidth: true
                        text: "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.\n\nThe software is provided \"as is\", without warranty of any kind, express or implied, including but not limited to merchantability, fitness for a particular purpose, and noninfringement."
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.68)
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                        wrapMode: Text.WordWrap
                        lineHeight: 1.18
                        lineHeightMode: Text.ProportionalHeight
                    }
                }
            }

            RowLayout {
                width: parent.width - 8
                x: 4
                spacing: 6

                Rectangle {
                    id: openConfigButton
                    Layout.fillWidth: true
                    height: 34
                    radius: 10
                    color: openConfigArea.pressed
                        ? Qt.alpha(t("accent", "#9ccfa0"), 0.24)
                        : Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                    border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.28)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Open config folder"
                        color: t("fg", "#eef6ef")
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: openConfigArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                            onClicked: root.openPath(root.configDir)
                    }
                }

                Rectangle {
                    id: openShellButton
                    Layout.preferredWidth: 120
                    height: 34
                    radius: 10
                    color: openShellArea.pressed
                        ? Qt.alpha(t("dim", "#45475a"), 0.22)
                        : Qt.alpha(t("dim", "#45475a"), 0.16)
                    border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Open shell.qml"
                        color: Qt.alpha(t("fg", "#eef6ef"), 0.8)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: openShellArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.openEditorPath(root.configDir + "/shell.qml")
                    }
                }
            }
        }
    }
}
