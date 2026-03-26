import QtQuick
import Quickshell.Io

Row {
    spacing: 10
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    property var theme: ({})

    property real cpuVal: 0
    property real ramVal: 0

    function refreshStats() {
        statsProc.running = false
        statsProc.running = true
    }

    StatPill {
        label: "CPU"
        value: cpuVal
        accent: cpuVal > 85
            ? (theme.red       || "#f38ba8")
            : (theme.accent    || "#89b4fa")
        trackColor: theme.dim  || "#45475a"
        textColor:  theme.fg   || "#cdd6f4"
    }

    StatPill {
        label: "RAM"
        value: ramVal
        accent: ramVal > 85
            ? (theme.red       || "#f38ba8")
            : (theme.highlight || "#cba6f7")
        trackColor: theme.dim  || "#45475a"
        textColor:  theme.fg   || "#cdd6f4"
    }

    Process {
        id: statsProc
        command: ["bash", "-c", "printf '%s\n' \"$(cat /proc/stat | head -1)\"; free | awk '/^Mem/{printf \"%d\\n\",$3/$2*100}'"]
        property var last: null
        running: true
        stdout: SplitParser {
            property int lineNo: 0
            onRead: data => {
                const text = data.trim()
                if (!text) return

                if (lineNo === 0) {
                    const p = text.split(/\s+/).slice(1).map(Number)
                    if (statsProc.last) {
                        const idle  = p[3] - statsProc.last[3]
                        const total = p.reduce((a, b) => a + b, 0) - statsProc.last.reduce((a, b) => a + b, 0)
                        cpuVal = total > 0 ? Math.round((1 - idle / total) * 100) : cpuVal
                    }
                    statsProc.last = p
                } else {
                    ramVal = parseInt(text) || 0
                }
                lineNo++
            }
        }
        onExited: statsProc.stdout.lineNo = 0
    }

    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: refreshStats()
    }
}
