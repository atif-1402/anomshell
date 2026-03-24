import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "modules"

PanelWindow {
    id: root

    property var launcher:      null
    property var calendarPopup: null
    property var notifServer: null

    property string bg:        "#1e1e2e"
    property string fg:        "#cdd6f4"
    property string accent:    "#89b4fa"
    property string dim:       "#45475a"
    property string highlight: "#cba6f7"
    property string red:       "#f38ba8"
    property string green:     "#a6e3a1"
    property string muted:     "#585b70"

    anchors { top: true; left: true; right: true }
    margins { top: 5; left: 6; right: 6 }
    implicitHeight: 28
    color: "transparent"
    exclusiveZone: 33

    Rectangle {
        anchors.fill: parent
        radius: 10
        color:  root.bg

        Behavior on color {
            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Item {
            id: leftSection
            anchors.left:           parent.left
            anchors.leftMargin:     12
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            width:  leftRow.implicitWidth

            Row {
                id: leftRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "\ue900"
                    color:          root.accent
                    font.pixelSize: 18
                    font.family:    "roundomarchy"
                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            if (root.launcher)
                                root.launcher.showing = !root.launcher.showing
                        }
                    }
                }

                Workspaces {
                    anchors.verticalCenter: parent.verticalCenter
                    theme: ({
                        fg:     root.fg,
                        accent: root.accent,
                        dim:    root.dim,
                        muted:  root.muted,
                        bg:     root.bg
                    })
                }

                Rectangle {
                    width:   1; height: 10
                    color:   root.dim
                    opacity: 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    visible: mediaModule.hasMedia
                    Behavior on color {
                        ColorAnimation { duration: 400 }
                    }
                }

                Media {
                    id:     mediaModule
                    anchors.verticalCenter: parent.verticalCenter
                    accent: root.accent
                    fg:     root.fg
                    green:  root.green
                    muted:  root.muted
                }
            }
        }

        Clock {
            anchors.centerIn: parent
            theme: ({
                fg:     root.fg,
                muted:  root.muted,
                accent: root.accent,
                dim:    root.dim,
                bg:     root.bg
            })
        }

        Item {
            id: rightSection
            anchors.right:          parent.right
            anchors.rightMargin:    12
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            width:  rightRow.implicitWidth

            Row {
                id: rightRow
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing:         12
                layoutDirection: Qt.RightToLeft

                Text {
                    id: powerBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "⏻"
                    color:          root.muted
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: powerBtn.color = root.red
                        onExited:  powerBtn.color = root.muted
                    }
                }

                Rectangle {
                    width: 1; height: 12
                    color: root.dim
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Text {
                    id: ccBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text:           ""
                    font.pixelSize: 13
                    font.family:    "JetBrainsMono Nerd Font Propo"
                    color:          controlCenter.showing ? root.accent : root.muted
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            controlCenter.showing = !controlCenter.showing
                            controlCenter.theme = ({
                                fg:     root.fg,
                                accent: root.accent,
                                dim:    root.dim,
                                muted:  root.muted,
                                bg:     root.bg
                            })
                        }
                    }
                }

                Text {
                    id: notifBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.notifServer && root.notifServer.notifications.length > 0 ? "󱅫" : "󰂚"
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font Propo"
                    color: root.notifServer && root.notifServer.panelOpen ? root.accent : root.muted
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.notifServer) root.notifServer.togglePanel()
                    }
                }

                Tray {
                    anchors.verticalCenter: parent.verticalCenter
                    trayWindow: root
                    theme: ({
                        fg:     root.fg,
                        accent: root.accent,
                        dim:    root.dim,
                        muted:  root.muted,
                        bg:     root.bg
                    })
                }

                Rectangle {
                    width: 1; height: 12
                    color: root.dim
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Stats {
                    anchors.verticalCenter: parent.verticalCenter
                    theme: ({
                        fg:        root.fg,
                        accent:    root.accent,
                        highlight: root.highlight,
                        dim:       root.dim,
                        red:       root.red,
                        green:     root.green,
                        muted:     root.muted,
                        bg:        root.bg
                    })
                }
                
                Rectangle {
                    width: 1; height: 12
                    color: root.dim
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
                
                Indicators {
                    anchors.verticalCenter: parent.verticalCenter
                    accent: root.accent
                    muted:  root.muted
                    red:    root.red
                    green:  root.green
                    fg:     root.fg
                }

            }
        }
    }
}