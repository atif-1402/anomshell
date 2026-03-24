import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property string accent: "#89b4fa"
    property string muted:  "#585b70"
    property string red:    "#f38ba8"
    property string green:  "#a6e3a1"
    property string fg:     "#cdd6f4"

    implicitWidth:  indicatorRow.implicitWidth
    implicitHeight: 28

    // ── update ───────────────────────────────────────────────────
    property bool updateAvailable: false

    Process {
        id: updateChecker
        command: ["bash", "-c",
            "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; " +
            "omarchy-update-available 2>/dev/null; echo $?"]
        running: true
        stdout: SplitParser {
            property string buf: ""
            onRead: data => buf += data + "\n"
        }
        onExited: {
            var out = updateChecker.stdout.buf.toLowerCase()
            root.updateAvailable = out.indexOf("up to date") === -1
            updateChecker.stdout.buf = ""
        }
    }

    Timer {
        interval: 21600000 // 6 hours
        running:  true
        repeat:   true
        onTriggered: {
            updateChecker.running = false
            updateChecker.running = true
        }
    }

    // ── idle ─────────────────────────────────────────────────────
    property bool idleDisabled: false

    Process {
        id: idleChecker
        command: ["bash", "-c", "pgrep -x hypridle > /dev/null && echo running || echo stopped"]
        running: true
        stdout: SplitParser {
            onRead: data => root.idleDisabled = data.trim() === "stopped"
        }
    }

    Timer {
        interval: 3000
        running:  true
        repeat:   true
        onTriggered: {
            idleChecker.running = false
            idleChecker.running = true
        }
    }

    // ── notification silencing ────────────────────────────────────
    property bool notifSilenced: false

    Process {
        id: notifChecker
        command: ["bash", "-c", "makoctl mode 2>/dev/null | grep -q do-not-disturb && echo dnd || echo normal"]
        running: true
        stdout: SplitParser {
            onRead: data => root.notifSilenced = data.trim() === "dnd"
        }
    }

    Timer {
        interval: 3000
        running:  true
        repeat:   true
        onTriggered: {
            notifChecker.running = false
            notifChecker.running = true
        }
    }

    // ── screen recording ─────────────────────────────────────────
    property bool isRecording: false

    Process {
        id: recordingChecker
        command: ["bash", "-c", "pgrep -f '^gpu-screen-recorder' > /dev/null && echo recording || echo stopped"]
        running: true
        stdout: SplitParser {
            onRead: data => root.isRecording = data.trim() === "recording"
        }
    }

    Timer {
        interval: 2000
        running:  true
        repeat:   true
        onTriggered: {
            recordingChecker.running = false
            recordingChecker.running = true
        }
    }

    // ── shell helpers ─────────────────────────────────────────────
    property int _cmdSeq: 0

    function runCmd(cmd) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash","-c",""]; running: false }',
            root, "proc" + (++_cmdSeq)
        )
        proc.command = ["bash", "-c", "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; " + cmd]
        proc.running = true
    }

    // ── UI ────────────────────────────────────────────────────────
    Row {
        id:                     indicatorRow
        anchors.verticalCenter: parent.verticalCenter
        spacing:                8

        // update indicator
        Text {
            visible:                root.updateAvailable
            anchors.verticalCenter: parent.verticalCenter
            text:                   ""
            color:                  root.green
            font.pixelSize:         13
            font.family:            "JetBrainsMono Nerd Font"

            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.runCmd(
                    "omarchy-launch-floating-terminal-with-presentation omarchy-update")
                onEntered: parent.opacity = 0.7
                onExited:  parent.opacity = 1.0
            }
        }

        // idle disabled indicator
        Text {
            visible:                root.idleDisabled
            anchors.verticalCenter: parent.verticalCenter
            text:                   "󱫖"
            color:                  root.accent
            font.pixelSize:         13
            font.family:            "JetBrainsMono Nerd Font"

            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                hoverEnabled: true
                onClicked:    root.runCmd("omarchy-toggle-idle")
                onEntered:    parent.opacity = 0.7
                onExited:     parent.opacity = 1.0
            }
        }

        // notification silencing indicator
        Text {
            visible:                root.notifSilenced
            anchors.verticalCenter: parent.verticalCenter
            text:                   "󰂛"
            color:                  root.accent
            font.pixelSize:         13
            font.family:            "JetBrainsMono Nerd Font"

            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                hoverEnabled: true
                onClicked:    root.runCmd("omarchy-toggle-notification-silencing")
                onEntered:    parent.opacity = 0.7
                onExited:     parent.opacity = 1.0
            }
        }

        // screen recording indicator — pulsing red when active
        Text {
            id:                     recordingIcon
            visible:                root.isRecording
            anchors.verticalCenter: parent.verticalCenter
            text:                   "󰻂"
            color:                  root.red
            font.pixelSize:         13
            font.family:            "JetBrainsMono Nerd Font"

            SequentialAnimation on opacity {
                loops:   Animation.Infinite
                running: root.isRecording
                NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked: root.runCmd("export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; omarchy-cmd-screenrecord --stop-recording")
            }
        }
    }
}