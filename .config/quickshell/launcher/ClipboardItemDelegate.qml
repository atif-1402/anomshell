import QtQuick

Item {
    id: root

    property var entry: ({})
    property bool selected: false
    property var theme: ({})

    signal clicked
    signal removeRequested

    width: ListView.view ? ListView.view.width : 0
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: selected
            ? Qt.alpha(theme.accent || "#89b4fa", 0.14)
            : (rowMa.containsMouse ? Qt.alpha(theme.dim || "#45475a", 0.35) : "transparent")
        border.width: 1
        border.color: selected
            ? Qt.alpha(theme.accent || "#89b4fa", 0.34)
            : Qt.alpha(theme.dim || "#45475a", 0.5)

        Behavior on color {
            ColorAnimation { duration: 90 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 90 }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (entry && entry.isBinaryHint) ? "󰋩" : "󰈔"
                color: selected
                    ? (theme.accent || "#89b4fa")
                    : Qt.alpha(theme.muted || "#585b70", 0.75)
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 90
                text: (entry && entry.preview) ? entry.preview : ""
                color: theme.fg || "#cdd6f4"
                elide: Text.ElideRight
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }

            Item { width: 1; height: 1 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                color: Qt.alpha(theme.red || "#f38ba8", rowMa.containsMouse ? 0.95 : 0.75)
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mouse.accepted = true
                        root.removeRequested()
                    }
                }
            }
        }
    }

    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
