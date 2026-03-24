import QtQuick
import QtQuick.Layouts

Item {
    property string icon:  ""
    property real   value: 0.5
    property var    theme: ({})

    signal moved(real v)
    signal iconClicked()

    implicitHeight: 36

    Row {
        anchors.fill:        parent
        anchors.rightMargin: 4
        spacing: 8

        Text {
            id: iconTxt
            anchors.verticalCenter: parent.verticalCenter
            text:           icon
            color:          theme.accent || "#89b4fa"
            font.pixelSize: 16
            font.family:    "JetBrainsMono Nerd Font"
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill:    parent
                anchors.margins: -6
                cursorShape:     Qt.PointingHandCursor
                hoverEnabled:    true
                onEntered: iconTxt.color = theme.fg     || "#cdd6f4"
                onExited:  iconTxt.color = theme.accent || "#89b4fa"
                onClicked: iconClicked()
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            // subtract icon + its spacing + label + its spacing
            width:  parent.width - iconTxt.implicitWidth - 8 - pctLabel.implicitWidth - 8
            height: 20

            Rectangle {
                id:           sliderTrack
                anchors.verticalCenter: parent.verticalCenter
                width:        parent.width
                height:       4
                radius:       99
                color:        theme.dim || "#45475a"

                Rectangle {
                    width:  sliderTrack.width * Math.min(Math.max(value, 0), 1)
                    height: parent.height
                    radius: 99
                    color:  theme.accent || "#89b4fa"
                    Behavior on width { SmoothedAnimation { velocity: 200 } }
                }
            }

            MouseArea {
                anchors.fill:         parent
                anchors.topMargin:    -8
                anchors.bottomMargin: -8
                cursorShape:          Qt.PointingHandCursor
                onPressed:           mouse => updateVal(mouse.x)
                onPositionChanged:   mouse => updateVal(mouse.x)

                function updateVal(x) {
                    moved(Math.min(Math.max(x / sliderTrack.width, 0), 1))
                }
            }
        }

        Text {
            id:             pctLabel
            anchors.verticalCenter: parent.verticalCenter
            text:           Math.round(value * 100) + "% "
            color:          theme.muted || "#585b70"
            font.pixelSize: 10
            font.family:    "JetBrainsMono Nerd Font"
            width:          36
            horizontalAlignment: Text.AlignRight
        }
    }
}