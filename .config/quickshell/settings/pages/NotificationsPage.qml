import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property var state: null
    property var theme: ({})

    function t(key, fallback) { return theme[key] || fallback }

    readonly property var positions: [
        { key: "top-center", label: "Top Center" },
        { key: "top-right", label: "Top Right" },
        { key: "top-left", label: "Top Left" },
        { key: "bottom-center", label: "Bottom Center" },
        { key: "bottom-right", label: "Bottom Right" },
        { key: "bottom-left", label: "Bottom Left" }
    ]

    function currentPosition() {
        return root.state ? root.state.notificationPosition : "top-center"
    }

    function setPosition(key) {
        if (!root.state) return
        root.state.notificationPosition = key
    }

    function sendTestNotification() {
        Quickshell.execDetached([
            "bash", "-lc",
            "notify-send -a Quickshell -u normal 'Quickshell Settings' 'This is a test notification.'"
        ])
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Qt.darker(t("bg", "#0b100c"), 1.04)
            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.1)
            border.width: 1
            implicitHeight: 216

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Text {
                    text: "Toast location"
                    color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                    font.pixelSize: 9
                    font.family: "JetBrains Mono"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: root.positions

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 10
                            color: root.currentPosition() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                                : Qt.alpha(t("dim", "#45475a"), 0.14)
                            border.color: root.currentPosition() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                                : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.currentPosition() === modelData.key
                                    ? t("fg", "#eef6ef")
                                    : Qt.alpha(t("fg", "#eef6ef"), 0.72)
                                font.pixelSize: 9
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPosition(modelData.key)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 10
                        color: Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                        border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.28)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Send test notification"
                            color: t("fg", "#eef6ef")
                            font.pixelSize: 9
                            font.family: "JetBrains Mono"
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sendTestNotification()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 94
                        height: 34
                        radius: 10
                        color: Qt.alpha(t("dim", "#45475a"), 0.16)
                        border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Reset"
                            color: Qt.alpha(t("fg", "#eef6ef"), 0.8)
                            font.pixelSize: 9
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setPosition("top-center")
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 14
            color: Qt.darker(t("bg", "#0f1410"), 1.02)
            border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
            border.width: 1
            implicitHeight: 70

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 3

                Text {
                    text: "Current"
                    color: Qt.alpha(t("muted", "#9fb29f"), 0.74)
                    font.pixelSize: 8
                    font.family: "JetBrains Mono"
                }

                Text {
                    text: root.currentPosition()
                    color: t("fg", "#eef6ef")
                    font.pixelSize: 11
                    font.family: "JetBrains Mono"
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Top center is the default toast position."
                    color: Qt.alpha(t("muted", "#9fb29f"), 0.55)
                    font.pixelSize: 8
                    font.family: "JetBrains Mono"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
