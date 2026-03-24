import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool active: false

    signal clicked

    anchors { left: true; right: true; top: true; bottom: true }
    color:         "transparent"
    exclusiveZone: -1
    visible:       active
    WlrLayershell.layer: WlrLayer.Top

    MouseArea {
        anchors.fill: parent
        onClicked:    root.clicked()
    }
}