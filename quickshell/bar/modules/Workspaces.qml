import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    spacing: 0
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    property var theme: ({})

    readonly property var roman: ["I","II","III","IV","V","VI","VII","VIII","IX"]

    Repeater {
        model: 9

        delegate: Item {
            id: ws
            property int  wsId:     index + 1
            property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)
            property bool active:   Hyprland.focusedWorkspace?.id === wsId
            property bool hovered:  mouseArea.containsMouse
            property bool pressed:  mouseArea.pressed

            implicitWidth:  active ? Math.max(lbl.implicitWidth + 14, 24) : 18
            implicitHeight: 28

            Behavior on implicitWidth {
                SmoothedAnimation { velocity: 180; easing.type: Easing.OutCubic }
            }

            // Press scale effect
            transform: Scale {
                origin.x: ws.implicitWidth / 2
                origin.y: ws.implicitHeight / 2
                xScale: ws.pressed ? 0.82 : 1.0
                yScale: ws.pressed ? 0.82 : 1.0

                Behavior on xScale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                Behavior on yScale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }

            Text {
                id: lbl
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter:   parent.verticalCenter
                anchors.verticalCenterOffset: -1

                text: roman[index]

                color: ws.active
                    ? (theme.accent || "#798186")
                    : ws.hovered
                        ? (theme.fg    || "#cacccc")   // hover = full fg
                        : ws.occupied
                            ? (theme.fg    || "#cacccc")
                            : (theme.muted   || "#2a2e30")

                opacity: ws.pressed ? 0.6 : 1.0

                font.pixelSize: ws.active ? 11 : ws.hovered ? 11 : 10
                font.family:    "JetBrains Mono"
                font.weight:    ws.active || ws.hovered ? Font.Medium : Font.Normal

                Behavior on color          { ColorAnimation  { duration: 150 } }
                Behavior on opacity        { NumberAnimation { duration: 80  } }
                Behavior on font.pixelSize { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom:           parent.bottom
                anchors.bottomMargin:     4

                width:  (ws.active || ws.hovered) ? lbl.implicitWidth + 4 : 0
                height: 1.5
                radius: 99
                opacity: ws.active ? 1.0 : 0.4   // dim underline on hover-only
                color:  theme.accent || "#798186"

                Behavior on width   { SmoothedAnimation { velocity: 120; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation   { duration: 150 } }
                Behavior on color   { ColorAnimation    { duration: 150 } }
            }

            MouseArea {
                id:           mouseArea
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                hoverEnabled: true
                onClicked:    Hyprland.dispatch("workspace " + ws.wsId)
            }
        }
    }
}