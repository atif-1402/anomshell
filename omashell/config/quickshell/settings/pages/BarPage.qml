import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var state: null
    property var theme: ({})

    function t(key, fallback) { return theme[key] || fallback }

    function currentPosition() {
        return root.state ? root.state.barPosition : "top"
    }

    function setPosition(pos) {
        if (root.state)
            root.state.barPosition = pos
    }

    function currentStyle() {
        return root.state ? root.state.barStyle : "dock"
    }

    function setStyle(styleKey) {
        if (root.state) {
            root.state.barStyle = styleKey
            if (root.state.barPosition !== "top" && root.state.barPosition !== "bottom")
                root.state.barPosition = "top"
        }
    }

    readonly property var positions: [
        { key: "top", label: "Top Edge", desc: "Classic bar placement" },
        { key: "bottom", label: "Bottom Edge", desc: "Dock-like placement" }
    ]
    readonly property var styles: [
        { key: "dock", label: "Dock", desc: "Original compact dock-style bar with rounded corners." },
        { key: "flat", label: "Flat", desc: "Edge-to-edge strip with square corners." }
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
                implicitHeight: 142

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Visual treatment"
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                    }

                    Repeater {
                        model: root.styles

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 10
                            color: root.currentStyle() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                                : Qt.alpha(t("dim", "#45475a"), 0.14)
                            border.color: root.currentStyle() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                                : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: root.currentStyle() === modelData.key ? "*" : ""
                                    color: t("accent", "#9ccfa0")
                                    font.pixelSize: 10
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
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setStyle(modelData.key)
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
                implicitHeight: 132

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "Placement"
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.8)
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                    }

                    Repeater {
                        model: root.positions

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 10
                            color: root.currentPosition() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.18)
                                : Qt.alpha(t("dim", "#45475a"), 0.14)
                            border.color: root.currentPosition() === modelData.key
                                ? Qt.alpha(t("accent", "#9ccfa0"), 0.34)
                                : Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: root.currentPosition() === modelData.key ? "*" : ""
                                    color: t("accent", "#9ccfa0")
                                    font.pixelSize: 10
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
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPosition(modelData.key)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                radius: 14
                color: Qt.darker(t("bg", "#0f1410"), 1.02)
                border.color: Qt.alpha(t("accent", "#9ccfa0"), 0.08)
                border.width: 1
                implicitHeight: 76

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
                        text: root.currentStyle() + " / " + root.currentPosition()
                        color: t("fg", "#eef6ef")
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "Changes apply live to the main bar."
                        color: Qt.alpha(t("muted", "#9fb29f"), 0.55)
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
