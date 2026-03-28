import QtQuick
import QtQuick.Layouts

Rectangle {
    property string icon:   ""
    property string label:  ""
    property bool   active: false
    property var    theme:  ({})

    signal toggled()

    implicitHeight: 56
    radius:         10
    color:          active
        ? Qt.alpha(theme.accent || "#89b4fa", 0.15)
        : Qt.alpha(theme.dim   || "#45475a",  0.3)
    border.color:   active
        ? Qt.alpha(theme.accent || "#89b4fa", 0.4)
        : "transparent"
    border.width: 1

    Behavior on color        { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           icon
            color:          active ? (theme.accent || "#89b4fa") : (theme.muted || "#585b70")
            font.pixelSize: 18
            font.family:    "JetBrainsMono Nerd Font"
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           label
            color:          active ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
            font.pixelSize: 9
            font.family:    "JetBrainsMono Nerd Font"
            elide:          Text.ElideRight
            width:          parent.parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    toggled()
    }
}