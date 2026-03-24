import QtQuick
import Quickshell.Io

Row {
    spacing: 10
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    property var theme: ({})

    property real cpuVal: 0
    property real ramVal: 0

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
        id: cpuProc
        command: ["bash", "-c", "cat /proc/stat | head -1"]
        property var last: null
        running: true
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(/\s+/).slice(1).map(Number)
                if (cpuProc.last) {
                    const idle  = p[3] - cpuProc.last[3]
                    const total = p.reduce((a,b)=>a+b,0) - cpuProc.last.reduce((a,b)=>a+b,0)
                    cpuVal = Math.round((1 - idle/total) * 100)
                }
                cpuProc.last = p
            }
        }
    }

    Process {
        id: ramProc
        command: ["bash", "-c", "free | awk '/^Mem/{printf \"%d\",$3/$2*100}'"]
        running: true
        stdout: SplitParser {
            onRead: data => { ramVal = parseInt(data.trim()) || 0 }
        }
    }

    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: {
            cpuProc.running = false; cpuProc.running = true
            ramProc.running = false; ramProc.running = true
        }
    }
}