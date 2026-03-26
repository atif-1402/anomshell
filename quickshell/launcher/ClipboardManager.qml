import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool showing: false
    property var theme: ({})

    anchors { bottom: true }
    margins { bottom: 5 }

    implicitWidth: 700
    implicitHeight: 440
    color: "transparent"
    exclusiveZone: 0
    visible: showing

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    ClipboardService {
        id: service
        active: root.showing
        query: root.searchText
    }

    property string searchText: ""

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                if (root.searchText.length > 0)
                    root.searchText = ""
                else
                    root.showing = false
                e.accepted = true
            } else if (e.key === Qt.Key_Down) {
                service.moveDown()
                listView.positionViewAtIndex(service.selectedIdx, ListView.Contain)
                e.accepted = true
            } else if (e.key === Qt.Key_Up) {
                service.moveUp()
                listView.positionViewAtIndex(service.selectedIdx, ListView.Contain)
                e.accepted = true
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                service.copySelected()
                root.showing = false
                e.accepted = true
            } else if (e.key === Qt.Key_Delete) {
                service.deleteSelected()
                e.accepted = true
            } else if (e.key === Qt.Key_Backspace) {
                if (root.searchText.length > 0)
                    root.searchText = root.searchText.slice(0, -1)
                else
                    root.showing = false
                e.accepted = true
            } else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32) {
                root.searchText += e.text
                e.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip: true

            opacity: root.showing ? 1 : 0
            transform: Translate {
                y: root.showing ? 0 : 20
                Behavior on y {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Row {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰆈"
                        color: theme.accent || "#89b4fa"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clipboard"
                        color: theme.fg || "#cdd6f4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 22
                        width: clearAllText.implicitWidth + 14
                        radius: 11
                        color: Qt.alpha(theme.red || "#f38ba8", 0.16)
                        border.width: 1
                        border.color: Qt.alpha(theme.red || "#f38ba8", 0.30)

                        Text {
                            id: clearAllText
                            anchors.centerIn: parent
                            text: "clear all"
                            color: Qt.alpha(theme.red || "#f38ba8", 0.95)
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: service.clearAll()
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: Qt.alpha(theme.muted || "#585b70", 0.6)
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showing = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: Qt.alpha(theme.dim || "#45475a", 0.4)
                    border.color: theme.accent || "#89b4fa"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍉"
                            color: theme.accent || "#89b4fa"
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.searchText !== "" ? root.searchText : "Search clipboard history..."
                            color: root.searchText !== ""
                                ? (theme.fg || "#cdd6f4")
                                : Qt.alpha(theme.muted || "#585b70", 0.5)
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1.5
                            height: 13
                            radius: 1
                            color: theme.accent || "#89b4fa"
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: root.showing
                                NumberAnimation { to: 0; duration: 530; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 530; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.searchText !== ""
                            text: "✕"
                            color: Qt.alpha(theme.muted || "#585b70", 0.5)
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.searchText = ""
                            }
                        }
                    }
                }

                Row {
                    Layout.fillWidth: true
                    Text {
                        text: service.filtered.length + " items"
                        color: Qt.alpha(theme.muted || "#585b70", 0.45)
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "↵ copy  del remove  esc close"
                        color: Qt.alpha(theme.muted || "#585b70", 0.35)
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: service.loading

                    Text {
                        anchors.centerIn: parent
                        text: "Loading clipboard history..."
                        color: Qt.alpha(theme.muted || "#585b70", 0.5)
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !service.loading && service.backendError !== ""

                    Text {
                        anchors.centerIn: parent
                        text: service.backendError
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 40
                        wrapMode: Text.Wrap
                        color: Qt.alpha(theme.red || "#f38ba8", 0.85)
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: listView
                            anchors.fill: parent
                            visible: !service.loading && service.backendError === "" && service.filtered.length > 0
                            model: service.filtered
                            spacing: 4
                            clip: true

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                width: 2
                            }

                            delegate: ClipboardItemDelegate {
                                entry: modelData
                                selected: index === service.selectedIdx
                                theme: root.theme
                                onClicked: {
                                    service.select(index)
                                    listView.positionViewAtIndex(service.selectedIdx, ListView.Contain)
                                }
                                onRemoveRequested: service.deleteEntry(modelData)
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: !service.loading && service.backendError === "" && service.filtered.length === 0

                            Text {
                                anchors.centerIn: parent
                                text: root.searchText.length > 0 ? "No matches found" : "Clipboard is empty"
                                color: Qt.alpha(theme.muted || "#585b70", 0.5)
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: service.hasImagePreview ? 340 : 0
                        Layout.fillHeight: true
                        visible: service.hasImagePreview
                        radius: 9
                        color: Qt.alpha(theme.dim || "#45475a", 0.22)
                        border.width: 1
                        border.color: Qt.alpha(theme.accent || "#89b4fa", 0.22)
                        clip: true

                        Behavior on Layout.preferredWidth {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Rectangle {
                                width: parent.width
                                height: parent.height - 36
                                radius: 6
                                color: Qt.alpha(theme.bg || "#1e1e2e", 0.9)
                                border.width: 1
                                border.color: Qt.alpha(theme.dim || "#45475a", 0.75)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: service.previewSource
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    cache: false
                                }
                            }

                            Text {
                                text: "Image Preview"
                                color: theme.fg || "#cdd6f4"
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Medium
                            }

                            Text {
                                text: service.previewMime
                                color: Qt.alpha(theme.muted || "#585b70", 0.7)
                                font.pixelSize: 8
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                    }
                }
            }
        }
    }

    onShowingChanged: {
        if (showing) {
            searchText = ""
            service.refresh()
            focusTimer.start()
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }
}
