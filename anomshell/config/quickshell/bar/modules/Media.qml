import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property string accent: "#89b4fa"
    property string fg: "#cdd6f4"
    property string green: "#a6e3a1"
    property string muted: "#585b70"
    property string bg: "#1e1e2e"
    property string albumHex: ""
    readonly property color paletteAccent: root.albumHex !== "" ? ("#" + root.albumHex) : root.accent
    readonly property color cardColor: root.albumHex !== ""
        ? Qt.tint(root.bg, Qt.alpha(root.paletteAccent, 0.18))
        : Qt.tint(root.bg, Qt.alpha(root.fg, 0.035))
    readonly property color cardBorder: Qt.alpha(root.fg, 0.07)
    readonly property color subtleSurface: root.albumHex !== ""
        ? Qt.tint(root.bg, Qt.alpha(root.paletteAccent, 0.10))
        : Qt.tint(root.bg, Qt.alpha(root.fg, 0.03))
    readonly property color subtleBorder: Qt.alpha(root.fg, 0.05)
    readonly property color strongText: Qt.alpha(root.fg, 0.92)
    readonly property color mutedText: Qt.alpha(root.fg, 0.56)
    readonly property color softText: Qt.alpha(root.fg, 0.42)
    readonly property color playSurface: Qt.tint(root.bg, Qt.alpha(root.paletteAccent, 0.22))
    readonly property color visualizerColor: Qt.lighter(root.accent, 1.18)

    property var player: {
        const all = Mpris.players.values
        if (all.length === 0)
            return null
        for (let i = 0; i < all.length; i++) {
            if (all[i].playbackState === MprisPlaybackState.Playing)
                return all[i]
        }
        return all[0]
    }

    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string artUrl: ""
    property string elapsedLabel: "0:00"
    property string durationLabel: "0:00"
    property real elapsedSeconds: 0
    property real durationSeconds: 0
    property real progress: 0
    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing ?? false
    property bool hasMedia: trackTitle !== ""
    property bool hasCava: false
    property bool hasWave: false
    property var cavaInputs: ["pipewire", "pulse"]
    property int cavaInputIdx: 0
    property string cavaCarry: ""
    property var cavaTokens: []
    property bool hoverOpen: false
    property bool dockBottom: false
    property real progressPhase: 0

    implicitWidth: hasMedia ? 126 : 0
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    opacity: hasMedia ? 1 : 0

    function formatSeconds(totalSeconds) {
        const secs = Math.max(0, Math.floor(totalSeconds || 0))
        const minutes = Math.floor(secs / 60)
        const seconds = secs % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    function openCard() {
        if (!root.hasMedia)
            return
        hideCardTimer.stop()
        root.hoverOpen = true
    }

    function closeCardSoon() {
        hideCardTimer.restart()
    }

    function shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\"'\"'") + "'"
    }

    function updateAlbumPalette() {
        if (!root.artUrl) {
            root.albumHex = ""
            return
        }

        const localArt = root.artUrl.startsWith("file://")
            ? root.artUrl.slice(7)
            : root.artUrl

        runShell(`
            img=` + shellQuote(localArt) + `
            if [ ! -e "$img" ] && [[ "$img" != http://* && "$img" != https://* ]]; then
                exit 0
            fi
            magick "$img" -resize 1x1\\! -alpha off -format '%[hex:p{0,0}]' info:- 2>/dev/null | head -c 6
        `, function(out) {
            const hex = (out || "").trim().replace(/[^0-9a-fA-F]/g, "").slice(0, 6)
            root.albumHex = hex.length === 6 ? hex : ""
        })
    }

    function cavaCommand(inputMethod) {
        return "CFG=/tmp/quickshell-media-cava.conf; " +
            "cat > \"$CFG\" <<'EOF'\n" +
            "[general]\n" +
            "bars = 26\n" +
            "framerate = 30\n" +
            "sensitivity = 100\n" +
            "lower_cutoff_freq = 45\n" +
            "higher_cutoff_freq = 10000\n" +
            "\n" +
            "[input]\n" +
            "method = " + inputMethod + "\n" +
            "source = auto\n" +
            "\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 1000\n" +
            "bar_delimiter = 59\n" +
            "channels = mono\n" +
            "EOF\n" +
            "exec cava -p \"$CFG\" 2>/dev/null"
    }

    function syncPlayerState() {
        if (!player) {
            trackTitle = ""
            trackArtist = ""
            trackAlbum = ""
            artUrl = ""
            albumHex = ""
            elapsedSeconds = 0
            durationSeconds = 0
            progress = 0
            elapsedLabel = "0:00"
            durationLabel = "0:00"
            hasWave = false
            return
        }

        const title = (player.trackTitle || "").trim()
        const state = player.playbackState
        const usable = title !== "" && (
            state === MprisPlaybackState.Playing ||
            state === MprisPlaybackState.Paused
        )

        if (!usable) {
            trackTitle = ""
            trackArtist = ""
            trackAlbum = ""
            artUrl = ""
            albumHex = ""
            elapsedSeconds = 0
            durationSeconds = 0
            progress = 0
            elapsedLabel = "0:00"
            durationLabel = "0:00"
            hasWave = false
            return
        }

        trackTitle = title
        refreshSnapshot()
    }

    function runShell(cmd, done) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash","-lc",""]; running: false; stdout: SplitParser { property string buf: ""; onRead: d => buf += d + "\\n" } }',
            root,
            "mediaProc" + Math.random().toString().slice(2)
        )
        proc.command = ["bash", "-lc", cmd]
        proc.onExited.connect(function() {
            const out = proc.stdout && proc.stdout.buf ? proc.stdout.buf : ""
            if (done)
                done(out)
            proc.destroy()
        })
        proc.running = true
    }

    function refreshSnapshot() {
        runShell(`
            players=$(playerctl -l 2>/dev/null)
            active=""
            for player in $players; do
                status=$(playerctl -p "$player" status 2>/dev/null)
                if [ "$status" = "Playing" ]; then
                    active="$player"
                    break
                fi
                if [ -z "$active" ]; then
                    active="$player"
                fi
            done

            if [ -z "$active" ]; then
                printf 'NONE'
                exit 0
            fi

            status=$(playerctl -p "$active" status 2>/dev/null)
            title=$(playerctl -p "$active" metadata --format '{{xesam:title}}' 2>/dev/null)
            artist=$(playerctl -p "$active" metadata --format '{{xesam:artist}}' 2>/dev/null)
            album=$(playerctl -p "$active" metadata --format '{{xesam:album}}' 2>/dev/null)
            art=$(playerctl -p "$active" metadata --format '{{mpris:artUrl}}' 2>/dev/null)
            length=$(playerctl -p "$active" metadata --format '{{mpris:length}}' 2>/dev/null)
            position=$(playerctl -p "$active" position 2>/dev/null)

            printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s' \
                "$status" "$title" "$artist" "$album" "$art" "$length"
            printf '\x1f%s' "$position"
        `, function(out) {
            const raw = (out || "").trim()
            if (!raw || raw === "NONE")
                return

            const parts = raw.split("\u001f")
            if (parts.length < 7)
                return

            const status = parts[0] || ""
            const title = (parts[1] || "").trim()
            if (title === "") {
                root.trackTitle = ""
                root.hasWave = false
                return
            }

            const artist = (parts[2] || "").trim()
            const album = (parts[3] || "").trim()
            const art = (parts[4] || "").trim()
            const lengthMicros = parseInt(parts[5])
            const positionSecs = parseFloat(parts[6])
            const durationSecs = isNaN(lengthMicros) ? 0 : Math.max(0, lengthMicros / 1000000)
            const elapsedSecs = isNaN(positionSecs) ? 0 : Math.max(0, positionSecs)

            root.trackTitle = title
            root.trackArtist = artist
            root.trackAlbum = album
            root.artUrl = art
            root.elapsedSeconds = elapsedSecs
            root.durationSeconds = durationSecs
            root.progress = durationSecs > 0 ? Math.max(0, Math.min(1, elapsedSecs / durationSecs)) : 0
            root.elapsedLabel = root.formatSeconds(elapsedSecs)
            root.durationLabel = root.formatSeconds(durationSecs)
            root.isPlaying = status === "Playing"
            root.updateAlbumPalette()
        })
    }

    function playerControl(action) {
        runShell(`
            players=$(playerctl -l 2>/dev/null)
            active=""
            for player in $players; do
                status=$(playerctl -p "$player" status 2>/dev/null)
                if [ "$status" = "Playing" ]; then
                    active="$player"
                    break
                fi
                if [ -z "$active" ]; then
                    active="$player"
                fi
            done
            [ -n "$active" ] || exit 0
            playerctl -p "$active" ` + action + ` 2>/dev/null
        `, function() {
            refreshDelay.restart()
        })
    }

    function applyCavaChunk(data) {
        if (!root.isPlaying || !root.hasMedia)
            return

        const chunks = (root.cavaCarry + (data || "")).split(";")
        root.cavaCarry = chunks.pop()

        for (const chunk of chunks) {
            const value = parseInt((chunk || "").trim())
            if (!isNaN(value))
                root.cavaTokens.push(value)
        }

        while (root.cavaTokens.length >= waveCanvas.bars.length) {
            const frame = root.cavaTokens.slice(0, waveCanvas.bars.length)
            root.cavaTokens = root.cavaTokens.slice(waveCanvas.bars.length)

            const next = frame.map(value => Math.max(0, Math.min(value / 1000, 1.0)))
            if (!root.hasWave && next.some(v => v > 0))
                root.hasWave = true
            if (!root.hasWave)
                continue

            const smooth = waveCanvas.bars.slice()
            for (let i = 0; i < smooth.length; i++)
                smooth[i] = smooth[i] * 0.62 + next[i] * 0.38
            waveCanvas.bars = smooth
            waveCanvas.requestPaint()
        }
    }

    onPlayerChanged: syncPlayerState()

    Connections {
        target: root.player
        function onTrackTitleChanged() { root.syncPlayerState() }
        function onPlaybackStateChanged() { root.syncPlayerState() }
        function onMetadataChanged() { root.syncPlayerState() }
    }

    Behavior on implicitWidth {
        SmoothedAnimation { velocity: 180; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Behavior on progress {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Process {
        id: cavaProbe
        running: true
        command: ["bash", "-lc", "command -v cava >/dev/null 2>&1 && printf 1 || printf 0"]
        stdout: SplitParser {
            onRead: data => root.hasCava = data.trim() === "1"
        }
        onExited: {
            if (root.hasCava)
                cavaProc.running = true
        }
    }

    Process {
        id: cavaProc
        command: ["bash", "-lc", root.cavaCommand(root.cavaInputs[root.cavaInputIdx])]
        running: false
        stdout: SplitParser {
            onRead: data => root.applyCavaChunk(data)
        }
        onExited: {
            if (!root.hasCava)
                return
            root.cavaCarry = ""
            root.cavaTokens = []
            root.cavaInputIdx = (root.cavaInputIdx + 1) % root.cavaInputs.length
            cavaRestart.restart()
        }
    }

    Timer {
        id: cavaRestart
        interval: 1200
        repeat: false
        onTriggered: {
            if (!root.hasCava)
                return
            cavaProc.command = ["bash", "-lc", root.cavaCommand(root.cavaInputs[root.cavaInputIdx])]
            cavaProc.running = true
        }
    }

    Timer {
        id: refreshDelay
        interval: 180
        repeat: false
        onTriggered: root.refreshSnapshot()
    }

    Timer {
        id: progressTimer
        interval: 1000
        repeat: true
        running: root.hoverOpen && root.hasMedia
        onTriggered: root.refreshSnapshot()
    }

    Timer {
        id: progressTick
        interval: 120
        repeat: true
        running: root.hoverOpen && root.hasMedia && root.isPlaying && root.durationSeconds > 0
        onTriggered: {
            root.elapsedSeconds = Math.min(root.durationSeconds, root.elapsedSeconds + interval / 1000)
            root.progress = Math.max(0, Math.min(1, root.elapsedSeconds / root.durationSeconds))
            root.elapsedLabel = root.formatSeconds(root.elapsedSeconds)
        }
    }

    Timer {
        id: hideCardTimer
        interval: 140
        repeat: false
        onTriggered: root.hoverOpen = false
    }

    Timer {
        id: progressWaveTimer
        interval: 33
        repeat: true
        running: root.hoverOpen && root.hasMedia && root.isPlaying
        onTriggered: {
            root.progressPhase += 0.11
            progressStroke.requestPaint()
        }
    }

    Timer {
        id: flattenTimer
        interval: 70
        repeat: true
        running: false
        onTriggered: {
            let allFlat = true
            const next = waveCanvas.bars.slice()
            for (let i = 0; i < next.length; i++) {
                next[i] = Math.max(0, next[i] - 0.05)
                if (next[i] > 0.01)
                    allFlat = false
            }
            waveCanvas.bars = next
            waveCanvas.requestPaint()
            if (allFlat) {
                flattenTimer.stop()
                root.hasWave = false
                waveCanvas.requestPaint()
            }
        }
    }

    MouseArea {
        id: compactHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: root.openCard()
        onExited: root.closeCardSoon()
    }

    Rectangle {
        id: compactChip
        anchors.fill: parent
        radius: 8
        color: "transparent"
    }

    Row {
        id: compactRow
        z: 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        spacing: 6

        Rectangle {
            width: 6
            height: 6
            radius: 99
            anchors.verticalCenter: parent.verticalCenter
            color: root.isPlaying ? root.green : root.muted

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            SequentialAnimation on scale {
                running: root.isPlaying
                loops: Animation.Infinite
                NumberAnimation { to: 1.4; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        Item {
            width: 94
            height: 14
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: titleTxt
                anchors.verticalCenter: parent.verticalCenter
                text: root.trackTitle
                color: root.fg
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"

                onTextChanged: x = 0

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: titleTxt.implicitWidth > 94

                    NumberAnimation {
                        to: -(titleTxt.implicitWidth + 18)
                        duration: (titleTxt.implicitWidth + 18) * 52
                        easing.type: Easing.Linear
                    }
                    PropertyAction { value: 94 }
                    NumberAnimation {
                        to: 0
                        duration: 94 * 52
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    PanelWindow {
        id: playerPopup
        visible: true
        implicitWidth: 318
        implicitHeight: root.hasMedia && root.hoverOpen ? 106 : 0
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: !root.dockBottom
            bottom: root.dockBottom
            left: true
        }
        margins {
            top: root.dockBottom ? 0 : Math.max(0, root.mapToItem(null, 0, root.height).y + 10 )
            bottom: root.dockBottom ? Math.max(0, root.screen.height - root.mapToItem(null, 0, 0).y + 10) : 0
            left: Math.max(6, root.mapToItem(null, 0, 0).x + 114)
        }

        Rectangle {
            id: playerCard
            anchors.fill: parent
            radius: 18
            color: root.cardColor
            border.color: root.cardBorder
            border.width: 1
            clip: true
            opacity: root.hoverOpen && root.hasMedia ? 1 : 0
            scale: root.hoverOpen && root.hasMedia ? 1 : 0.972

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: cardHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: root.openCard()
                onExited: root.closeCardSoon()
            }

            Canvas {
                id: ambientGlowBack
                anchors.fill: parent
                opacity: root.hasMedia ? 1 : 0

                property real glow1x: 214
                property real glow1y: 8
                property real glow2x: 156
                property real glow2y: 54

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    function paintGlow(x, y, radius, alpha) {
                        const grad = ctx.createRadialGradient(x, y, 0, x, y, radius)
                        grad.addColorStop(0.0, Qt.alpha(root.paletteAccent, alpha))
                        grad.addColorStop(0.45, Qt.alpha(root.paletteAccent, alpha * 0.28))
                        grad.addColorStop(1.0, Qt.alpha(root.paletteAccent, 0.0))
                        ctx.fillStyle = grad
                        ctx.beginPath()
                        ctx.arc(x, y, radius, 0, Math.PI * 2)
                        ctx.fill()
                    }

                    paintGlow(ambientGlowBack.glow1x, ambientGlowBack.glow1y, 104, 0.14)
                    paintGlow(ambientGlowBack.glow2x, ambientGlowBack.glow2y, 76, 0.08)
                }

                SequentialAnimation on glow1x {
                    loops: Animation.Infinite
                    running: root.hoverOpen && root.hasMedia
                    NumberAnimation { to: 228; duration: 3600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 202; duration: 3900; easing.type: Easing.InOutSine }
                }

                SequentialAnimation on glow1y {
                    loops: Animation.Infinite
                    running: root.hoverOpen && root.hasMedia
                    NumberAnimation { to: 18; duration: 3000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 2; duration: 3800; easing.type: Easing.InOutSine }
                }

                SequentialAnimation on glow2x {
                    loops: Animation.Infinite
                    running: root.hoverOpen && root.hasMedia
                    NumberAnimation { to: 172; duration: 3300; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 144; duration: 3600; easing.type: Easing.InOutSine }
                }

                SequentialAnimation on glow2y {
                    loops: Animation.Infinite
                    running: root.hoverOpen && root.hasMedia
                    NumberAnimation { to: 42; duration: 2800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 60; duration: 3400; easing.type: Easing.InOutSine }
                }
            }

            Canvas {
                id: waveCanvas
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                height: 30
                opacity: 0.36

                property var bars: {
                    const values = []
                    for (let i = 0; i < 26; i++)
                        values.push(0)
                    return values
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    if (!root.hasWave)
                        return

                    const cornerInset = playerCard.radius
                    const pts = []
                    const baseY = height
                    const amp = height * 0.78
                    const drawWidth = Math.max(1, width - cornerInset * 2)
                    const step = drawWidth / Math.max(1, bars.length - 1)

                    for (let i = 0; i < bars.length; i++) {
                        pts.push({
                            x: cornerInset + i * step,
                            y: baseY - Math.max(0, Math.min(1, bars[i])) * amp
                        })
                    }

                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    ctx.lineTo(cornerInset * 0.45, height)
                    ctx.lineTo(pts[0].x, pts[0].y)
                    for (let i = 0; i < pts.length - 1; i++) {
                        const a = pts[i]
                        const b = pts[i + 1]
                        const mx = (a.x + b.x) * 0.5
                        const my = (a.y + b.y) * 0.5
                        ctx.quadraticCurveTo(a.x, a.y, mx, my)
                    }
                    ctx.lineTo(width - cornerInset * 0.45, height)
                    ctx.lineTo(width, height)
                    ctx.closePath()
                    ctx.fillStyle = Qt.alpha(root.visualizerColor, 0.22)
                    ctx.fill()
                }
            }

            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: 72
                    height: 72
                    radius: 0
                    color: root.subtleSurface
                    border.color: root.subtleBorder
                    border.width: 1

                    Image {
                        id: coverImage
                        anchors.fill: parent
                        source: root.artUrl
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        mipmap: true
                        visible: status === Image.Ready && source !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !coverImage.visible
                        text: "󰎆"
                        color: Qt.alpha(root.paletteAccent, 0.82)
                        font.pixelSize: 22
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Column {
                    width: parent.width - 138
                    spacing: 1

                    Text {
                        width: parent.width
                        text: root.trackTitle
                        color: root.strongText
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.trackArtist !== "" ? root.trackArtist : (root.trackAlbum !== "" ? root.trackAlbum : "Media")
                        color: root.mutedText
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.elapsedLabel + " / " + root.durationLabel
                        color: root.softText
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                    }

                    Item {
                        width: parent.width
                        height: 3
                    }

                    Row {
                        width: parent.width
                        spacing: 7

                        Text {
                            text: "󰒮"
                            color: root.mutedText
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.playerControl("previous")
                            }
                        }

                        Item {
                            id: progressWrap
                            width: parent.width - 32
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter

                            Canvas {
                                id: progressStroke
                                anchors.fill: parent

                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    const trackY = height * 0.56
                                    const activeWidth = Math.max(8, (width - 8) * root.progress)
                                    const step = 5
                                    const livePhase = root.progressPhase

                                    ctx.beginPath()
                                    ctx.moveTo(0, trackY)
                                    ctx.lineTo(width, trackY)
                                    ctx.lineWidth = 1
                                    ctx.lineCap = "round"
                                    ctx.lineJoin = "round"
                                    ctx.strokeStyle = Qt.alpha(root.fg, 0.22)
                                    ctx.stroke()

                                    ctx.beginPath()
                                    ctx.moveTo(0, trackY)
                                    let prevX = 0
                                    let prevY = trackY
                                    for (let x = step; x <= activeWidth + step; x += step) {
                                        const px = Math.min(activeWidth, x)
                                        const py = trackY + Math.sin((px / 6.8) + livePhase) * (root.isPlaying ? 0.78 : 0.34)
                                        const cx = (prevX + px) * 0.5
                                        const cy = (prevY + py) * 0.5
                                        ctx.quadraticCurveTo(prevX, prevY, cx, cy)
                                        prevX = px
                                        prevY = py
                                    }
                                    ctx.lineTo(activeWidth, prevY)
                                    ctx.lineWidth = 1.8
                                    ctx.lineCap = "round"
                                    ctx.lineJoin = "round"
                                    ctx.strokeStyle = root.paletteAccent
                                    ctx.stroke()
                                }
                            }
                        }

                        Text {
                            text: "󰒭"
                            color: root.mutedText
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.playerControl("next")
                            }
                        }
                    }
                }

                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.playSurface
                    border.color: Qt.alpha(root.paletteAccent, 0.18)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.isPlaying ? "󰏤" : "󰐊"
                        color: root.paletteAccent
                        font.pixelSize: 15
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playerControl("play-pause")
                    }
                }
            }
        }
    }
}
