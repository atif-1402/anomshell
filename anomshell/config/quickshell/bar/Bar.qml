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
    property var powerActions: null
    property var settings: null

    property string bg:        "#1e1e2e"
    property string fg:        "#cdd6f4"
    property string accent:    "#89b4fa"
    property string dim:       "#45475a"
    property string highlight: "#cba6f7"
    property string red:       "#f38ba8"
    property string green:     "#a6e3a1"
    property string muted:     "#585b70"
    readonly property string launcherIconPreset: settings?.launcherIconPreset || "omarchy"
    readonly property string launcherIconText: launcherIconPreset === "arch"
        ? ""
        : launcherIconPreset === "hyprland"
            ? ""
            : launcherIconPreset === "nix"
                ? ""
                : launcherIconPreset === "command"
                    ? "󰘳"
                    : launcherIconPreset === "windows"
                        ? "󰖳"
                        : "\ue900"
    readonly property string launcherIconFont: launcherIconPreset === "omarchy"
        ? "Omarchy"
        : "JetBrainsMono Nerd Font Propo"
    readonly property int launcherIconSize: settings?.launcherIconSize || 12

    readonly property bool barOnBottom: (settings?.barPosition || "top") === "bottom"
    readonly property string barStyle: settings?.barStyle || "dock"
    readonly property bool styleFlat: barStyle === "flat"
    readonly property int barHeight: styleFlat ? 30 : 28
    readonly property int edgeMargin: styleFlat ? 0 : 5
    readonly property int sideMargin: styleFlat ? 0 : 6
    readonly property int reservedSpace: styleFlat ? 30 : 33
    readonly property int barRadius: styleFlat ? 0 : 10

    anchors {
        top: !barOnBottom
        bottom: barOnBottom
        left: true
        right: true
    }
    margins {
        top: barOnBottom ? 0 : root.edgeMargin
        bottom: barOnBottom ? root.edgeMargin : 0
        left: root.sideMargin
        right: root.sideMargin
    }
    implicitHeight: root.barHeight
    color: "transparent"
    exclusiveZone: root.reservedSpace

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        color: root.bg
        opacity: 1
        border.width: root.styleFlat ? 0 : 1
        border.color: Qt.rgba(1, 1, 1, 0.03)

        Behavior on color {
            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Item {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: root.barHeight
            width: leftRow.implicitWidth

            Row {
                id: leftRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.launcherIconText
                    color: root.accent
                    font.pixelSize: root.launcherIconSize
                    font.family: root.launcherIconFont

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.launcher)
                                root.launcher.showing = !root.launcher.showing
                        }
                    }
                }

                Workspaces {
                    anchors.verticalCenter: parent.verticalCenter
                    settings: root.settings
                    theme: ({
                        fg: root.fg,
                        accent: root.accent,
                        dim: root.dim,
                        muted: root.muted,
                        bg: root.bg
                    })
                }

                Rectangle {
                    width: 1
                    height: 10
                    color: root.dim
                    opacity: 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    visible: mediaModule.hasMedia

                    Behavior on color {
                        ColorAnimation { duration: 400 }
                    }
                }

                Media {
                    id: mediaModule
                    anchors.verticalCenter: parent.verticalCenter
                    accent: root.accent
                    fg: root.fg
                    green: root.green
                    muted: root.muted
                    dockBottom: root.barOnBottom
                }
            }
        }

        Clock {
            anchors.centerIn: parent
            theme: ({
                fg: root.fg,
                muted: root.muted,
                accent: root.accent,
                dim: root.dim,
                bg: root.bg
            })
        }

        Item {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: root.barHeight
            width: rightRow.implicitWidth

            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                layoutDirection: Qt.RightToLeft

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font Propo"
                    color: controlCenter.showing ? root.accent : root.muted

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.showing = !controlCenter.showing
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.notifServer && root.notifServer.dndEnabled
                        ? "󰂛"
                        : root.notifServer && root.notifServer.notifications.length > 0
                            ? "󱅫"
                            : "󰂚"
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font Propo"
                    color: root.notifServer && root.notifServer.dndEnabled
                        ? root.red
                        : root.notifServer && root.notifServer.panelOpen
                            ? root.accent
                            : root.muted

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (!root.notifServer) return
                            if (mouse.button === Qt.RightButton) root.notifServer.toggleDnd()
                            else root.notifServer.togglePanel()
                        }
                    }
                }

                Tray {
                    anchors.verticalCenter: parent.verticalCenter
                    trayWindow: root
                    theme: ({
                        fg: root.fg,
                        accent: root.accent,
                        dim: root.dim,
                        muted: root.muted,
                        bg: root.bg
                    })
                }

                Rectangle {
                    width: 1
                    height: 12
                    color: root.dim
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Stats {
                    anchors.verticalCenter: parent.verticalCenter
                    theme: ({
                        fg: root.fg,
                        accent: root.accent,
                        highlight: root.highlight,
                        dim: root.dim,
                        red: root.red,
                        green: root.green,
                        muted: root.muted,
                        bg: root.bg
                    })
                }

                Rectangle {
                    width: 1
                    height: 12
                    color: root.dim
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Indicators {
                    anchors.verticalCenter: parent.verticalCenter
                    notifServer: root.notifServer
                    accent: root.accent
                    muted: root.muted
                    red: root.red
                    green: root.green
                    fg: root.fg
                }
            }
        }
    }
}
