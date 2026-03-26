import QtQuick
import QtQuick.Layouts

Item {
    property string icon:  ""
    property real   value: 0.5
    property var    theme: ({})

    signal moved(real v)
    signal iconClicked()

    implicitHeight: 34

    function c(key, fallback) { return theme[key] || fallback }
    property real clampedValue: Math.max(0, Math.min(value, 1))
    property real handleCenterX: Math.max(0, Math.min(sliderArea.width, sliderArea.width * clampedValue))

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        spacing: 10

        Text {
            id: iconTxt
            Layout.alignment: Qt.AlignVCenter
            text: icon
            color: iconMa.containsMouse ? (c("fg", "#cdd6f4")) : (c("muted", "#585b70"))
            font.pixelSize: 15
            font.family: "JetBrainsMono Nerd Font"
            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: iconMa
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: iconClicked()
            }
        }

        Item {
            id: sliderArea
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 28

            Rectangle {
                id: trackInactive
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 10
                radius: 5
                color: Qt.alpha(c("muted", "#585b70"), 0.65)
            }

            Rectangle {
                id: trackActive
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: handleCenterX
                height: trackInactive.height
                radius: trackInactive.radius
                color: Qt.alpha(c("accent", "#89b4fa"), 0.9)
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: thumb
                x: Math.max(0, Math.min(sliderArea.width - width, handleCenterX - width / 2))
                y: (sliderArea.height - height) / 2
                width: thumbMa.pressed ? 5 : 4
                height: thumbMa.pressed ? 24 : 22
                radius: 2
                color: c("accent", "#89b4fa")
                Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 70 } }
                Behavior on height { NumberAnimation { duration: 70 } }
            }

            MouseArea {
                id: thumbMa
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => update(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed) update(mouse.x)
                }

                function update(px) {
                    moved(Math.max(0, Math.min(px / sliderArea.width, 1)))
                }
            }
        }
    }
}
