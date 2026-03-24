import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property string accent: "#89b4fa"
    property string fg:     "#cdd6f4"
    property string green:  "#a6e3a1"
    property string muted:  "#585b70"

    property var player: {
        const all = Mpris.players.values
        if (all.length === 0) return null
        for (let i = 0; i < all.length; i++)
            if (all[i].playbackState === MprisPlaybackState.Playing)
                return all[i]
        return all[0]
    }

    property bool   isPlaying: player?.playbackState === MprisPlaybackState.Playing ?? false
    property string lastTitle: ""
    property bool   hasMedia:  lastTitle !== ""
    property bool   hasData:   false

    function scheduleRepaint() {
        viz.requestPaint()
    }

    onPlayerChanged: {
        if (!player) {
            lastTitle = ""
            hasData   = false
        } else if (player.trackTitle) {
            lastTitle = player.trackTitle
        }
    }

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: {
            const all = Mpris.players.values
            if (all.length === 0) {
                root.lastTitle = ""
                root.hasData   = false
            } else {
                const p = root.player
                if (p?.trackTitle) root.lastTitle = p.trackTitle
                else root.lastTitle = ""
            }
        }
    }

    Connections {
        target: root.player
        function onTrackTitleChanged() {
            if (root.player?.trackTitle)
                root.lastTitle = root.player.trackTitle
            else
                root.lastTitle = ""
        }
    }

    implicitWidth:  hasMedia ? 120 : 0
    implicitHeight: 28

    Behavior on implicitWidth {
        SmoothedAnimation { velocity: 160; easing.type: Easing.OutCubic }
    }

    opacity: hasMedia ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Process {
        id:      setup
        running: false
        command: ["bash", "-c", `
            mkdir -p ~/.config/cava
            cat > ~/.config/cava/quickshell.conf << 'CEOF'
[general]
bars = 24
framerate = 25

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /tmp/cava-qs
data_format = ascii
ascii_max_range = 100
bar_delimiter = 32
frame_delimiter = 10
CEOF
            [ -p /tmp/cava-qs ] || mkfifo /tmp/cava-qs
        `]
        onExited: {
            cavaProc.running   = true
            cavaReader.running = true
        }
    }

    Process {
        id:      cavaProc
        command: ["cava", "-p", "/home/atif/.config/cava/quickshell.conf"]
        running: false
    }

    Process {
        id:      cavaReader
        command: ["bash", "-c", "cat /tmp/cava-qs"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (!root.isPlaying) return
                const parts = data.trim().split(" ")
                if (parts.length < 2) return
                const vals = parts.map(v => {
                    const n = parseInt(v)
                    return isNaN(n) ? 0 : Math.min(n / 100, 1.0)
                })
                if (vals.length !== viz.bars.length) return

                // only paint once we have real non-zero data
                const hasReal = vals.some(v => v > 0)
                if (!root.hasData && hasReal) root.hasData = true
                if (!root.hasData) return

                const b = viz.bars.slice()
                for (let i = 0; i < b.length; i++) {
                    b[i] = b[i] * 0.6 + vals[i] * 0.4
                }
                b[0]          = 0
                b[b.length-1] = 0
                viz.bars = b
                viz.requestPaint()
            }
        }
    }

    Component.onCompleted: setup.running = true

    onIsPlayingChanged: {
        if (!isPlaying) flattenTimer.start()
        else            flattenTimer.stop()
    }

    Timer {
        id:       flattenTimer
        interval: 60
        repeat:   true
        running:  false
        onTriggered: {
            let allFlat = true
            const b = viz.bars.slice()
            for (let i = 0; i < b.length; i++) {
                b[i] = Math.max(0, b[i] - 0.04)
                if (b[i] > 0.01) allFlat = false
            }
            viz.bars = b
            viz.requestPaint()
            if (allFlat) {
                flattenTimer.stop()
                // clear canvas fully when flattened
                viz.hasData = false
                viz.requestPaint()
            }
        }
    }

    Canvas {
        id:     viz
        x:      0; y: 0
        width:  parent.width
        height: parent.height
        z:      0

        property var bars: {
            const b = []
            for (let i = 0; i < 24; i++) b.push(0)
            return b
        }

        // watch accent changes and repaint
        property string currentAccent: root.accent
        onCurrentAccentChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // if no real data yet, leave canvas blank (transparent)
            if (!root.hasData) return

            const n  = bars.length
            if (n < 2) return
            const bw = width / n
            const c  = root.accent

            function px(i) { return i * bw + bw / 2 }
            function py(i) { return height - bars[i] * height * 0.9 }

            ctx.beginPath()
            ctx.moveTo(-2, height)
            ctx.lineTo(-2, py(0))
            for (let i = 1; i < n; i++) {
                const cpx = (px(i-1) + px(i)) / 2
                ctx.bezierCurveTo(cpx, py(i-1), cpx, py(i), px(i), py(i))
            }
            ctx.lineTo(width + 2, py(n-1))
            ctx.lineTo(width + 2, height)
            ctx.closePath()
            ctx.fillStyle   = c
            ctx.globalAlpha = 0.15
            ctx.fill()

            ctx.beginPath()
            ctx.moveTo(-2, py(0))
            for (let i = 1; i < n; i++) {
                const cpx = (px(i-1) + px(i)) / 2
                ctx.bezierCurveTo(cpx, py(i-1), cpx, py(i), px(i), py(i))
            }
            ctx.lineTo(width + 2, py(n-1))
            ctx.strokeStyle = c
            ctx.lineWidth   = 1.2
            ctx.globalAlpha = 0.65
            ctx.stroke()

            ctx.globalAlpha = 1
        }
    }

    Row {
        id:      pillRow
        z:       1
        anchors.verticalCenter: parent.verticalCenter
        anchors.left:           parent.left
        anchors.leftMargin:     8
        spacing:                6

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6; height: 6; radius: 99
            color: root.isPlaying ? root.green : root.muted
            Behavior on color { ColorAnimation { duration: 200 } }

            SequentialAnimation on scale {
                running: root.isPlaying
                loops:   Animation.Infinite
                NumberAnimation { to: 1.4; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 90; height: 14
            clip:  true

            Text {
                id: titleTxt
                anchors.verticalCenter: parent.verticalCenter
                text:           root.lastTitle
                color:          root.fg
                font.pixelSize: 10
                font.family:    "JetBrainsMono Nerd Font"

                onTextChanged: x = 0

                SequentialAnimation on x {
                    loops:   Animation.Infinite
                    running: titleTxt.implicitWidth > 90

                    NumberAnimation {
                        to:          -(titleTxt.implicitWidth + 20)
                        duration:    (titleTxt.implicitWidth + 20) * 55
                        easing.type: Easing.Linear
                    }
                    PropertyAction { value: 90 }
                    NumberAnimation {
                        to:          0
                        duration:    90 * 55
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }
}