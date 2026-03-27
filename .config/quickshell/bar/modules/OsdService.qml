import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property bool showing: false
    property string icon: "󰕾"
    property string title: "Volume"
    property string subtitle: ""
    property string valueText: "0%"
    property string artUrl: ""
    property bool mediaMode: false
    property int value: 0
    property string tone: "accent"
    property int waveBars: 22
    property var wave: _emptyWave()
    property var cavaInputs: ["pipewire", "pulse"]
    property int cavaInputIdx: 0
    property string _cavaCarry: ""
    property var _cavaTokens: []
    property bool hasWpctl: false
    property bool hasBrightnessctl: false
    property bool hasPlayerctl: false
    property bool hasCava: false

    function _clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function _emptyWave() {
        const arr = []
        for (let i = 0; i < waveBars; i++) arr.push(0)
        return arr
    }

    function _show(iconGlyph, titleText, valuePercent, toneName) {
        icon = iconGlyph
        title = titleText
        subtitle = ""
        value = _clamp(Math.round(valuePercent), 0, 100)
        valueText = value + "%"
        artUrl = ""
        mediaMode = false
        tone = toneName
        hideTimer.interval = 1400
        showing = true
        hideTimer.restart()
    }

    function _formatSeconds(totalSeconds) {
        const secs = Math.max(0, Math.floor(totalSeconds || 0))
        const minutes = Math.floor(secs / 60)
        const seconds = secs % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    function _showMedia(snapshot, restartHide) {
        if (restartHide === false && (!showing || !mediaMode))
            return

        const lengthMicros = snapshot.lengthMicros
        const positionSecs = snapshot.positionSecs
        const durationSecs = lengthMicros > 0 ? (lengthMicros / 1000000) : 0
        const progress = durationSecs > 0
            ? _clamp((positionSecs / durationSecs) * 100, 0, 100)
            : 0

        icon = snapshot.icon
        title = snapshot.title
        subtitle = snapshot.subtitle
        value = Math.round(progress)
        valueText = durationSecs > 0
            ? (_formatSeconds(positionSecs) + " / " + _formatSeconds(durationSecs))
            : _formatSeconds(positionSecs)
        artUrl = snapshot.artUrl
        mediaMode = true
        tone = snapshot.tone

        if (restartHide !== false) {
            hideTimer.interval = 2400
            showing = true
            hideTimer.restart()
        }
    }

    function _volumeIcon(level, muted) {
        if (muted || level <= 0) return "󰝟"
        if (level < 34) return "󰕿"
        if (level < 67) return "󰖀"
        return "󰕾"
    }

    function _applyCavaFrame(parts) {
        const out = []
        for (let i = 0; i < waveBars; i++) {
            const idx = Math.floor(i * (parts.length - 1) / Math.max(1, waveBars - 1))
            const n = parseInt(parts[idx])
            const target = isNaN(n) ? 0 : _clamp(n / 1000, 0, 1)
            const prev = (wave && i < wave.length) ? wave[i] : 0
            out.push((prev * 0.58) + (target * 0.42))
        }
        wave = out
    }

    function _applyCavaChunk(data) {
        const chunks = (_cavaCarry + (data || "")).split(";")
        _cavaCarry = chunks.pop()

        for (const c of chunks) {
            const n = parseInt((c || "").trim())
            if (!isNaN(n))
                _cavaTokens.push(n)
        }

        while (_cavaTokens.length >= waveBars) {
            const frame = _cavaTokens.slice(0, waveBars)
            _cavaTokens = _cavaTokens.slice(waveBars)
            _applyCavaFrame(frame)
        }
    }

    function _cavaCommand(inputMethod) {
        return "CFG=/tmp/quickshell-osd-cava.conf; " +
            "cat > \"$CFG\" <<'EOF'\n" +
            "[general]\n" +
            "bars = 22\n" +
            "framerate = 60\n" +
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

    function _parseWpctlVolume(raw) {
        const line = (raw || "").trim()
        const n = line.match(/([0-9]*\.?[0-9]+)/)
        const muted = /\bMUTED\b/i.test(line)
        const pct = n ? Math.round(parseFloat(n[1]) * 100) : 0
        return {
            value: muted ? 0 : _clamp(pct, 0, 100),
            muted: muted
        }
    }

    function _mediaPlayer() {
        const all = Mpris.players.values
        if (all.length === 0) return null
        for (let i = 0; i < all.length; i++)
            if (all[i].playbackState === MprisPlaybackState.Playing)
                return all[i]
        return all[0]
    }

    function _refreshMediaStatus() {
        Qt.callLater(function() {
            root.showMediaStatus()
        })
    }

    function _runShell(cmd, done) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash","-lc",""]; running: false; stdout: SplitParser { property string buf: ""; onRead: d => buf += d + "\\n" } }',
            root,
            "osdProc" + Math.random().toString().slice(2)
        )
        proc.command = ["bash", "-lc", cmd]
        proc.onExited.connect(function() {
            const out = proc.stdout && proc.stdout.buf ? proc.stdout.buf : ""
            if (done) done(out)
            proc.destroy()
        })
        proc.running = true
    }

    function _showUnavailable(titleText) {
        _show("󰧧", titleText, 0, "muted")
    }

    function _fetchMediaSnapshot(done) {
        _runShell(`
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

            printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s' \
                "$active" "$status" "$title" "$artist" "$album" "$art" "$length"
            printf '\x1f%s' "$position"
        `, function(out) {
            const raw = (out || "").trim()
            if (!raw || raw === "NONE") {
                done(null)
                return
            }

            const parts = raw.split("\u001f")
            if (parts.length < 8) {
                done(null)
                return
            }

            const status = parts[1]
            const title = parts[2] || "Media"
            const artist = parts[3] || ""
            const album = parts[4] || ""
            const art = parts[5] || ""
            const lengthMicros = parseInt(parts[6])
            const positionSecs = parseFloat(parts[7])
            const subtitle = artist && album ? artist + " • " + album : (artist || album || parts[0])
            const playing = status === "Playing"

            done({
                title: title,
                subtitle: subtitle,
                artUrl: art,
                lengthMicros: isNaN(lengthMicros) ? 0 : lengthMicros,
                positionSecs: isNaN(positionSecs) ? 0 : positionSecs,
                icon: playing ? "󰏤" : (status === "Paused" ? "󰐊" : "󰝚"),
                tone: playing ? "green" : (status === "Paused" ? "accent" : "muted")
            })
        })
    }

    Process {
        id: depsProbe
        command: ["bash", "-lc",
            "printf 'wpctl=%s\\n' \"$(command -v wpctl >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'brightnessctl=%s\\n' \"$(command -v brightnessctl >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'playerctl=%s\\n' \"$(command -v playerctl >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'cava=%s\\n' \"$(command -v cava >/dev/null 2>&1 && echo 1 || echo 0)\""
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("=")
                if (parts.length !== 2)
                    return
                const enabled = parts[1].trim() === "1"
                if (parts[0] === "wpctl")
                    root.hasWpctl = enabled
                else if (parts[0] === "brightnessctl")
                    root.hasBrightnessctl = enabled
                else if (parts[0] === "playerctl")
                    root.hasPlayerctl = enabled
                else if (parts[0] === "cava")
                    root.hasCava = enabled
            }
        }
        onExited: {
            if (root.hasCava)
                cavaProc.running = true
        }
    }

    Process {
        id: cavaProc
        command: ["bash", "-lc", root._cavaCommand(root.cavaInputs[root.cavaInputIdx])]
        running: false
        stdout: SplitParser {
            onRead: data => {
                root._applyCavaChunk(data)
            }
        }
        onExited: {
            if (!root.hasCava)
                return
            root.wave = root._emptyWave()
            root._cavaCarry = ""
            root._cavaTokens = []
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
            cavaProc.command = ["bash", "-lc", root._cavaCommand(root.cavaInputs[root.cavaInputIdx])]
            cavaProc.running = true
        }
    }

    function showVolume() {
        if (!hasWpctl) {
            _showUnavailable("Audio unavailable")
            return
        }
        _runShell("wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null", function(out) {
            const p = _parseWpctlVolume(out)
            _show(_volumeIcon(p.value, p.muted), "Volume", p.value, p.muted ? "red" : "accent")
        })
    }

    function showBrightness() {
        if (!hasBrightnessctl) {
            _showUnavailable("Brightness unavailable")
            return
        }
        _runShell("brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'", function(out) {
            const v = parseInt((out || "").trim())
            const pct = isNaN(v) ? 0 : _clamp(v, 0, 100)
            _show("󰃠", "Brightness", pct, "highlight")
        })
    }

    function showMic() {
        if (!hasWpctl) {
            _showUnavailable("Mic unavailable")
            return
        }
        _runShell("wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null", function(out) {
            const p = _parseWpctlVolume(out)
            _show(p.muted ? "󰍭" : "󰍬", "Mic", p.value, p.muted ? "red" : "green")
        })
    }

    function showMediaStatus() {
        if (!hasPlayerctl) {
            _showUnavailable("Media unavailable")
            return
        }
        const player = _mediaPlayer()
        if (!player) {
            _show("󰝚", "No Player", 0, "muted")
            return
        }

        _fetchMediaSnapshot(function(snapshot) {
            if (!snapshot) {
                if (player.playbackState === MprisPlaybackState.Playing)
                    _show("󰏤", player.trackTitle || "Playing", 0, "green")
                else if (player.playbackState === MprisPlaybackState.Paused)
                    _show("󰐊", player.trackTitle || "Paused", 0, "accent")
                else
                    _show("󰝚", player.identity || "Stopped", 0, "muted")
                return
            }

            _showMedia(snapshot, true)
        })
    }

    function volumeStep(delta) {
        if (!hasWpctl) {
            _showUnavailable("Audio unavailable")
            return
        }
        const sign = delta >= 0 ? "+" : "-"
        const pct = Math.abs(Math.round(delta))
        _runShell(
            "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + pct + "%" + sign + " 2>/dev/null; " +
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null",
            function(out) {
                const p = _parseWpctlVolume(out)
                _show(_volumeIcon(p.value, p.muted), "Volume", p.value, p.muted ? "red" : "accent")
            }
        )
    }

    function toggleMute() {
        if (!hasWpctl) {
            _showUnavailable("Audio unavailable")
            return
        }
        _runShell(
            "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null; " +
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null",
            function(out) {
                const p = _parseWpctlVolume(out)
                _show(_volumeIcon(p.value, p.muted), "Volume", p.value, p.muted ? "red" : "accent")
            }
        )
    }

    function brightnessStep(delta) {
        if (!hasBrightnessctl) {
            _showUnavailable("Brightness unavailable")
            return
        }
        const sign = delta >= 0 ? "+" : "-"
        const pct = Math.abs(Math.round(delta))
        _runShell(
            "brightnessctl set " + pct + "%" + sign + " 2>/dev/null; " +
            "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'",
            function(out) {
                const v = parseInt((out || "").trim())
                const valuePct = isNaN(v) ? 0 : _clamp(v, 0, 100)
                _show("󰃠", "Brightness", valuePct, "highlight")
            }
        )
    }

    function mediaPlayPause() {
        if (!hasPlayerctl) {
            _showUnavailable("Media unavailable")
            return
        }
        const player = _mediaPlayer()
        if (!player || !player.canControl) {
            _show("󰝚", "No Player", 0, "muted")
            return
        }

        if (player.canTogglePlaying) player.togglePlaying()
        else if (player.playbackState === MprisPlaybackState.Playing && player.canPause) player.pause()
        else if (player.canPlay) player.play()

        _refreshMediaStatus()
    }

    function mediaNext() {
        if (!hasPlayerctl) {
            _showUnavailable("Media unavailable")
            return
        }
        const player = _mediaPlayer()
        if (!player || !player.canControl || !player.canGoNext) {
            _show("󰝚", "No Player", 0, "muted")
            return
        }

        player.next()
        mediaRefreshDelay.restart()
    }

    function mediaPrev() {
        if (!hasPlayerctl) {
            _showUnavailable("Media unavailable")
            return
        }
        const player = _mediaPlayer()
        if (!player || !player.canControl || !player.canGoPrevious) {
            _show("󰝚", "No Player", 0, "muted")
            return
        }

        player.previous()
        mediaRefreshDelay.restart()
    }

    Timer {
        id: mediaRefreshDelay
        interval: 180
        repeat: false
        onTriggered: root.showMediaStatus()
    }

    Timer {
        id: mediaProgressTimer
        interval: 1000
        repeat: true
        running: root.showing && root.mediaMode
        onTriggered: {
            root._fetchMediaSnapshot(function(snapshot) {
                if (snapshot && root.showing && root.mediaMode)
                    root._showMedia(snapshot, false)
            })
        }
    }

    Timer {
        id: hideTimer
        interval: 1400
        repeat: false
        onTriggered: root.showing = false
    }
}
