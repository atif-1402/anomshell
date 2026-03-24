import QtQuick

Rectangle {
    property string label: ""
    property int size: 13

    implicitWidth: lbl.implicitWidth + 12
    implicitHeight: 20
    radius: 6
    color: ma.containsMouse ? "#25313244" : "transparent"

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: parent.label
        color: "#cdd6f4"
        font.pixelSize: parent.size
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
    }
}