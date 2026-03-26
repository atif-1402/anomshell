import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property var service: null
    property var settings: null
    property var theme: ({})

    function t(key, fallback) { return theme[key] || fallback }

    readonly property string osdPosition: settings?.osdPosition || "bottom-center"
    readonly property real reveal: service && service.showing ? 1 : 0
    readonly property int panelWidth: service && service.mediaMode ? 298 : 232
    readonly property int panelHeight: service && service.mediaMode ? 78 : 52
    readonly property int topOffset: 44
    readonly property int edgeOffset: 16

    function toneColor() {
        if (!service) return t("accent", "#89b4fa")
        if (service.tone === "red") return t("red", "#f38ba8")
        if (service.tone === "green") return t("green", "#a6e3a1")
        if (service.tone === "highlight") return t("highlight", "#cba6f7")
        if (service.tone === "muted") return t("muted", "#585b70")
        return t("accent", "#89b4fa")
    }

    Component {
        id: osdChrome

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 12
            color: root.t("bg", "#1e1e2e")
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            opacity: root.reveal
            y: (1 - root.reveal) * 4
            scale: 0.99 + (0.01 * root.reveal)
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }

            Behavior on y {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }

            Canvas {
                id: wave
                anchors.fill: parent
                opacity: 0.2

                Connections {
                    target: root.service
                    function onValueChanged() { wave.requestPaint() }
                    function onToneChanged() { wave.requestPaint() }
                    function onWaveChanged() { wave.requestPaint() }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const w = width
                    const h = height
                    ctx.clearRect(0, 0, w, h)
                    if (!root.service)
                        return

                    const samples = root.service.wave || []
                    if (samples.length < 2)
                        return

                    const baseY = h * 0.72
                    const amp = h * 0.34
                    const step = w / Math.max(1, samples.length - 1)
                    const pts = []

                    for (let i = 0; i < samples.length; i++) {
                        const x = i * step
                        const y = baseY - Math.max(0, Math.min(1, samples[i])) * amp
                        pts.push({ x: x, y: y })
                    }

                    ctx.beginPath()
                    ctx.moveTo(0, h)
                    ctx.lineTo(pts[0].x, pts[0].y)

                    for (let i2 = 0; i2 < pts.length - 1; i2++) {
                        const p0 = pts[i2]
                        const p1 = pts[i2 + 1]
                        const cx = (p0.x + p1.x) * 0.5
                        const cy = (p0.y + p1.y) * 0.5
                        ctx.quadraticCurveTo(p0.x, p0.y, cx, cy)
                    }

                    const plast = pts[pts.length - 1]
                    ctx.lineTo(plast.x, plast.y)
                    ctx.lineTo(w, h)
                    ctx.closePath()
                    ctx.fillStyle = Qt.alpha(root.toneColor(), 0.18)
                    ctx.fill()

                    ctx.beginPath()
                    ctx.moveTo(pts[0].x, pts[0].y)
                    for (let i3 = 0; i3 < pts.length - 1; i3++) {
                        const a = pts[i3]
                        const b = pts[i3 + 1]
                        const mx = (a.x + b.x) * 0.5
                        const my = (a.y + b.y) * 0.5
                        ctx.quadraticCurveTo(a.x, a.y, mx, my)
                    }
                    ctx.lineTo(plast.x, plast.y)
                    ctx.lineWidth = 1
                    ctx.strokeStyle = Qt.alpha(root.toneColor(), 0.38)
                    ctx.stroke()
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 7
                anchors.bottomMargin: 7
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        visible: root.service && root.service.mediaMode
                        Layout.preferredWidth: visible ? 42 : 0
                        Layout.preferredHeight: visible ? 42 : 0
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        clip: true

                        Image {
                            id: coverArt
                            anchors.fill: parent
                            source: root.service ? root.service.artUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            visible: status === Image.Ready && source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !coverArt.visible
                            text: "󰎆"
                            color: root.toneColor()
                            font.pixelSize: 18
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.service && root.service.subtitle ? 1 : 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: root.service ? root.service.icon : "󰕾"
                                color: root.toneColor()
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.service ? root.service.title : "OSD"
                                color: root.t("fg", "#cdd6f4")
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.family: "JetBrains Mono"
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.service ? root.service.valueText : "0%"
                                color: root.t("muted", "#585b70")
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                font.family: "JetBrains Mono"
                            }
                        }

                        Text {
                            visible: root.service && root.service.subtitle !== ""
                            Layout.fillWidth: true
                            text: root.service ? root.service.subtitle : ""
                            color: root.t("muted", "#585b70")
                            font.pixelSize: 9
                            font.family: "JetBrains Mono"
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 3
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.14)
                    clip: true

                    Rectangle {
                        width: parent.width * ((root.service ? root.service.value : 0) / 100)
                        height: parent.height
                        radius: 2
                        color: root.toneColor()

                        Behavior on width {
                            NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: root.osdPosition === "top-left" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { top: true; left: true }
        margins { top: root.topOffset; left: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "top-center" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { top: true }
        margins { top: root.topOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "top-right" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { top: true; right: true }
        margins { top: root.topOffset; right: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "bottom-left" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { bottom: true; left: true }
        margins { bottom: root.edgeOffset; left: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "bottom-center" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { bottom: true }
        margins { bottom: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "bottom-right" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { bottom: true; right: true }
        margins { bottom: root.edgeOffset; right: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }
}
