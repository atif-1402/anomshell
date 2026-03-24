import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire

PanelWindow {
    id: cc

    property var  theme:   ({})
    property bool showing: false

    visible: showing

    implicitWidth:  284
    implicitHeight: Math.min(mainCol.implicitHeight + 28, screen.height - 58)

    anchors { top: true; right: true }
    margins { top: 44; right: 10 }

    WlrLayershell.exclusiveZone: -1
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property bool   wifiEnabled:    false
    property string wifiSsid:       ""
    property bool   ethernetActive: false
    property string ethernetIface:  ""
    property bool   btEnabled:      false
    property bool   dndEnabled:     false
    property bool   showWifiList:   false
    property bool   showBtList:     false
    property var    wifiNetworks:   []
    property var    btDevices:      []

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    Process {
        id: wifiStatus
        command: ["bash", "-c",
            "nmcli radio wifi && nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 | head -1"]
        running: true
        stdout: SplitParser {
            property int ln: 0
            onRead: data => {
                const t = data.trim()
                if (ln === 0) cc.wifiEnabled = t === "enabled"
                else          cc.wifiSsid    = t
                ln++
            }
        }
        onExited: wifiStatus.stdout.ln = 0
    }

    Process {
        id: ethernetStatus
        command: ["bash", "-c",
            "ip link show | awk '/^[0-9]+: e[a-z0-9]+:.*UP/{gsub(/:$/,\"\",$2); print $2; exit}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const iface = data.trim()
                cc.ethernetActive = iface !== ""
                if (iface !== "") cc.ethernetIface = iface
            }
        }
    }

    Process {
        id: wifiScan
        command: ["bash", "-c",
            "nmcli -t -f ssid,signal,security dev wifi list 2>/dev/null | head -12"]
        running: false
        stdout: SplitParser {
            property var nets: []
            onRead: data => {
                const p = data.trim().split(":")
                if (p[0]?.trim()) nets.push({
                    ssid:   p[0].trim(),
                    signal: parseInt(p[1]) || 0,
                    secure: (p[2] || "--") !== "--"
                })
            }
        }
        onExited: {
            cc.wifiNetworks      = wifiScan.stdout.nets.slice()
            wifiScan.stdout.nets = []
        }
    }

    Process {
        id: btStatus
        command: ["bash", "-c", "bluetoothctl show | grep Powered | awk '{print $2}'"]
        running: true
        stdout: SplitParser {
            onRead: data => { cc.btEnabled = data.trim() === "yes" }
        }
    }

    Process {
        id: btScan
        command: ["bash", "-c", "bluetoothctl devices 2>/dev/null | head -8"]
        running: false
        stdout: SplitParser {
            property var devs: []
            onRead: data => {
                const m = data.trim().match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/)
                if (m) devs.push({ mac: m[1], name: m[2] })
            }
        }
        onExited: {
            cc.btDevices       = btScan.stdout.devs.slice()
            btScan.stdout.devs = []
        }
    }

    Process {
        id: briProc
        command: ["bash", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                if (!isNaN(v)) briSlider.value = v / 100
            }
        }
    }

    Timer {
        interval: 3000; running: cc.showing; repeat: true
        onTriggered: {
            wifiStatus.running     = false; wifiStatus.running     = true
            ethernetStatus.running = false; ethernetStatus.running = true
            btStatus.running       = false; btStatus.running       = true
        }
    }

    onShowingChanged: {
        if (showing) {
            wifiStatus.running     = false; wifiStatus.running     = true
            ethernetStatus.running = false; ethernetStatus.running = true
            btStatus.running       = false; btStatus.running       = true
            briProc.running        = false; briProc.running        = true
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius:       14
        color:        theme.bg  || "#1e1e2e"
        border.color: theme.dim || "#45475a"
        border.width: 1
        clip:         true

        states: [
            State {
                name: "open"; when: cc.showing
                PropertyChanges { target: slideX; x: 0 }
            },
            State {
                name: "closed"; when: !cc.showing
                PropertyChanges { target: slideX; x: 300 }
            }
        ]
        transitions: [
            Transition {
                from: "closed"; to: "open"
                NumberAnimation { target: slideX; property: "x"; duration: 240; easing.type: Easing.OutCubic }
            },
            Transition {
                from: "open"; to: "closed"
                NumberAnimation { target: slideX; property: "x"; duration: 200; easing.type: Easing.InCubic }
            }
        ]

        transform: Translate { id: slideX; x: 300 }

        Column {
            id: mainCol
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                topMargin: 14; leftMargin: 12; rightMargin: 12
            }
            spacing: 12

            // ── HEADER ────────────────────────────────────────────────────────
            Rectangle {
                width: parent.width; height: 62; radius: 12
                color: Qt.alpha(theme.surface || "#313244", 0.7)

                Row {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                    spacing: 12
                    Rectangle {
                        width: 38; height: 38; radius: 19
                        color: Qt.alpha(theme.accent || "#89b4fa", 0.15)
                        border.color: Qt.alpha(theme.accent || "#89b4fa", 0.4); border.width: 1
                        Text {
                            anchors.centerIn: parent; text: "󰀄"; font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font"; color: theme.accent || "#89b4fa"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 3
                        Text {
                            text: Quickshell.env("USER") || "user"
                            color: theme.fg || "#cdd6f4"
                            font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Medium
                        }
                        Text {
                            text: Quickshell.env("HOSTNAME") || "localhost"
                            color: theme.muted || "#585b70"
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }

                Row {
                    anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 12 }
                    spacing: 8
                    Repeater {
                        model: [
                            { icon: "󰌾", hoverColor: theme.accent || "#89b4fa", cmd: ["hyprlock"] },
                            { icon: "󰜉", hoverColor: "#fab387",                 cmd: ["systemctl", "reboot"] },
                            { icon: "󰐥", hoverColor: "#f38ba8",                 cmd: ["systemctl", "poweroff"] }
                        ]
                        delegate: Rectangle {
                            width: 30; height: 30; radius: 9
                            color: btnMa.containsMouse
                                ? Qt.alpha(modelData.hoverColor, 0.18)
                                : Qt.alpha(theme.dim || "#45475a", 0.4)
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Text {
                                anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 15
                                font.family: "JetBrainsMono Nerd Font"
                                color: btnMa.containsMouse ? modelData.hoverColor : (theme.muted || "#585b70")
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            MouseArea {
                                id: btnMa; anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: Quickshell.execDetached(modelData.cmd)
                            }
                        }
                    }
                }
            }

            // ── TOGGLES ROW 1 — Network · Bluetooth · DND ────────────────────
            Row {
                width: parent.width; spacing: 8

                // Network
                Rectangle {
                    width: (parent.width - 16) / 3; height: 72; radius: 12
                    color: (cc.ethernetActive || cc.wifiEnabled)
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.15)
                        : Qt.alpha(theme.dim    || "#45475a", 0.35)
                    border.color: (cc.ethernetActive || cc.wifiEnabled)
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? "󰈀" : cc.wifiEnabled ? "󰤨" : "󰤭"
                            color: (cc.ethernetActive || cc.wifiEnabled)
                                ? (theme.accent || "#89b4fa") : (theme.muted || "#585b70")
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? "Ethernet" : "Wi-Fi"
                            color: (cc.ethernetActive || cc.wifiEnabled)
                                ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? cc.ethernetIface
                                : (cc.wifiSsid !== "" ? cc.wifiSsid : (cc.wifiEnabled ? "On" : "Off"))
                            color: theme.muted || "#585b70"
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"
                            elide: Text.ElideRight; width: parent.parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (cc.ethernetActive) return
                            if (mouse.button === Qt.RightButton) {
                                cc.showWifiList = !cc.showWifiList; cc.showBtList = false
                                if (cc.showWifiList) { wifiScan.running = false; wifiScan.running = true }
                            } else {
                                Quickshell.execDetached(["nmcli", "radio", "wifi", cc.wifiEnabled ? "off" : "on"])
                                wifiStatus.running = false; wifiStatus.running = true
                            }
                        }
                    }
                }

                // Bluetooth
                Rectangle {
                    width: (parent.width - 16) / 3; height: 72; radius: 12
                    color: cc.btEnabled
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.15)
                        : Qt.alpha(theme.dim    || "#45475a", 0.35)
                    border.color: cc.btEnabled
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.btEnabled ? "󰂱" : "󰂲"
                            color: cc.btEnabled ? (theme.accent || "#89b4fa") : (theme.muted || "#585b70")
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Bluetooth"
                            color: cc.btEnabled ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.btEnabled ? "On" : "Off"
                            color: theme.muted || "#585b70"
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                cc.showBtList = !cc.showBtList; cc.showWifiList = false
                                if (cc.showBtList) { btScan.running = false; btScan.running = true }
                            } else {
                                Quickshell.execDetached(["bluetoothctl", "power", cc.btEnabled ? "off" : "on"])
                                btStatus.running = false; btStatus.running = true
                            }
                        }
                    }
                }

                // DND
                Rectangle {
                    width: (parent.width - 16) / 3; height: 72; radius: 12
                    color: cc.dndEnabled ? Qt.alpha("#fab387", 0.15) : Qt.alpha(theme.dim || "#45475a", 0.35)
                    border.color: cc.dndEnabled ? Qt.alpha("#fab387", 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.dndEnabled ? "󰂛" : "󰂚"
                            color: cc.dndEnabled ? "#fab387" : (theme.muted || "#585b70")
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "DND"
                            color: cc.dndEnabled ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.dndEnabled ? "On" : "Off"
                            color: theme.muted || "#585b70"
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cc.dndEnabled = !cc.dndEnabled
                            // mako: Quickshell.execDetached(["makoctl", "mode", cc.dndEnabled ? "-a" : "-r", "do-not-disturb"])
                        }
                    }
                }
            }

            // WiFi sub-list
            Column {
                width: parent.width; spacing: 3
                visible: cc.showWifiList && cc.wifiNetworks.length > 0
                Text {
                    text: "Available Networks"; color: theme.muted || "#585b70"
                    font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; bottomPadding: 2
                }
                Repeater {
                    model: cc.wifiNetworks
                    delegate: Rectangle {
                        width: parent.width; height: 34; radius: 8
                        color: wifiMa.containsMouse
                            ? Qt.alpha(theme.accent || "#89b4fa", 0.12)
                            : Qt.alpha(theme.dim    || "#45475a", 0.25)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12 }
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.signal > 66 ? "󰤨" : modelData.signal > 33 ? "󰤢" : "󰤟"
                                color: theme.accent || "#89b4fa"; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; text: modelData.ssid
                                color: modelData.ssid === cc.wifiSsid ? (theme.accent || "#89b4fa") : (theme.fg || "#cdd6f4")
                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                font.weight: modelData.ssid === cc.wifiSsid ? Font.Medium : Font.Normal
                                elide: Text.ElideRight; width: parent.width - 44
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.secure; text: "󰌾"
                                color: theme.muted || "#585b70"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                        MouseArea {
                            id: wifiMa; anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid])
                                cc.showWifiList = false
                                wifiStatus.running = false; wifiStatus.running = true
                            }
                        }
                    }
                }
            }

            // BT sub-list
            Column {
                width: parent.width; spacing: 3
                visible: cc.showBtList && cc.btDevices.length > 0
                Text {
                    text: "Paired Devices"; color: theme.muted || "#585b70"
                    font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; bottomPadding: 2
                }
                Repeater {
                    model: cc.btDevices
                    delegate: Rectangle {
                        width: parent.width; height: 34; radius: 8
                        color: btMa.containsMouse
                            ? Qt.alpha(theme.accent || "#89b4fa", 0.12)
                            : Qt.alpha(theme.dim    || "#45475a", 0.25)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰂯"; color: theme.accent || "#89b4fa"
                                font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                                color: theme.fg || "#cdd6f4"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                elide: Text.ElideRight; width: parent.parent.width - 50
                            }
                        }
                        MouseArea {
                            id: btMa; anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["bluetoothctl", "connect", modelData.mac])
                                cc.showBtList = false
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: theme.dim || "#45475a"; opacity: 0.3 }

            // ── SLIDERS ───────────────────────────────────────────────────────
            CCSlider {
                width: parent.width
                icon:  Pipewire.defaultAudioSink?.audio?.muted ?? false ? "󰝟" : "󰕾"
                value: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                theme: cc.theme
                onMoved: v => {
                    const s = Pipewire.defaultAudioSink
                    if (s?.audio) { s.audio.muted = false; s.audio.volume = v }
                }
                onIconClicked: {
                    const s = Pipewire.defaultAudioSink
                    if (s?.audio) s.audio.muted = !s.audio.muted
                }
            }
            CCSlider {
                width: parent.width
                icon:  Pipewire.defaultAudioSource?.audio?.muted ?? false ? "󰍭" : "󰍬"
                value: Pipewire.defaultAudioSource?.audio?.volume ?? 0
                theme: cc.theme
                onMoved: v => {
                    const s = Pipewire.defaultAudioSource
                    if (s?.audio) { s.audio.muted = false; s.audio.volume = v }
                }
                onIconClicked: {
                    const s = Pipewire.defaultAudioSource
                    if (s?.audio) s.audio.muted = !s.audio.muted
                }
            }
            CCSlider {
                id: briSlider; width: parent.width
                icon: "󰃞"; value: 0.5; theme: cc.theme
                onMoved: v => {
                    Quickshell.execDetached(["brightnessctl", "set", Math.round(v * 100) + "%"])
                }
            }

            Item { width: 1; height: 6 }
        }
    }
}