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
    property var  notifServer: null
    property var  powerActions: null
    property var  settingsWindow: null
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
    property string wifiDevice:     ""
    property string wifiState:      ""
    property string wifiConnection: ""
    property string wifiSsid:       ""
    property int    wifiSignal:     0
    property bool   wifiSecure:     false
    property bool   ethernetActive: false
    property string ethernetIface:  ""
    property bool   btEnabled:      false
    property string btConnectedName: ""
    property string btConnectedIconName: ""
    property int    btConnectedBattery: -1
    property int    btConnectedCount: 0
    property string lastBtNotifiedName: ""
    property string lastBtDisconnectedName: ""
    property bool   dndEnabled:     notifServer?.dndEnabled ?? false
    property bool   showWifiList:   false
    property bool   showBtList:     false
    property bool   wifiManagerOpen: false
    property bool   btManagerOpen:   false
    property var    wifiNetworks:   []
    property var    btDevices:      []
    property bool   hasNmcli:       false
    property bool   hasBluetoothctl: false
    property bool   hasBluetoothDevice: false
    property bool   btScanning: false
    property int    btScanTicks: 0
    property bool   wifiScanning: false
    property int    wifiScanTicks: 0
    property bool   hasBrightnessctl: false
    property bool   hasBrightnessDevice: false
    property bool   hasIp:          false

    function restart(proc) {
        proc.running = false
        proc.running = true
    }

    function refreshConnectivity() {
        if (hasNmcli)
            restart(wifiStatus)
        else {
            wifiEnabled = false
            wifiDevice = ""
            wifiState = ""
            wifiConnection = ""
            wifiSsid = ""
            wifiSignal = 0
            wifiSecure = false
            wifiNetworks = []
        }

        if (hasIp)
            restart(ethernetStatus)
        else {
            ethernetActive = false
            ethernetIface = ""
        }

        if (hasBluetoothctl && hasBluetoothDevice) {
            restart(btStatus)
            restart(btScan)
        } else {
            btEnabled = false
            btDevices = []
            btConnectedName = ""
            btConnectedIconName = ""
            btConnectedBattery = -1
            btConnectedCount = 0
        }
    }

    function refreshBrightness() {
        if (hasBrightnessctl && hasBrightnessDevice)
            restart(briProc)
    }

    function refreshWifiScan() {
        if (hasNmcli)
            restart(wifiScan)
    }

    function refreshBtScan() {
        if (hasBluetoothctl && hasBluetoothDevice) {
            if (btScan.running) return
            restart(btScan)
        }
    }

    function runNmcli(args) {
        if (hasNmcli)
            Quickshell.execDetached(["nmcli"].concat(args))
    }

    function runBluetoothctl(args) {
        if (hasBluetoothctl && hasBluetoothDevice)
            Quickshell.execDetached(["bluetoothctl"].concat(args))
    }

    function runBrightnessctl(args) {
        if (hasBrightnessctl && hasBrightnessDevice)
            Quickshell.execDetached(["brightnessctl"].concat(args))
    }

    function wifiStateLabel() {
        if (!wifiEnabled) return "Off"
        if (ethernetActive) return ethernetIface
        if (wifiState === "connected") return wifiSsid !== "" ? wifiSsid : "Connected"
        if (wifiState === "connecting") return "Connecting"
        if (wifiState === "failed") return "Failed"
        if (wifiState === "disconnected") return "Disconnected"
        if (wifiState !== "") return wifiState
        return "On"
    }

    function wifiStateColor() {
        if (!wifiEnabled) return theme.muted || "#585b70"
        if (wifiState === "connected") return theme.accent || "#89b4fa"
        if (wifiState === "connecting") return "#fab387"
        if (wifiState === "failed") return theme.red || "#f38ba8"
        return theme.muted || "#585b70"
    }

    Timer {
        id: btRescanTimer
        interval: 6500
        repeat: false
        onTriggered: {
            refreshBtScan()
            cc.btScanning = false
        }
    }

    Timer {
        interval: 7000
        running:  true
        repeat:   true
        onTriggered: refreshBtScan()
    }

    Timer {
        id: btScanTicker
        interval: 350
        repeat: true
        running: cc.btScanning
        onTriggered: cc.btScanTicks = (cc.btScanTicks + 1) % 4
    }

    Timer {
        id: wifiRescanTimer
        interval: 3500
        repeat: false
        onTriggered: cc.wifiScanning = false
    }

    Timer {
        id: wifiScanTicker
        interval: 350
        repeat: true
        running: cc.wifiScanning
        onTriggered: cc.wifiScanTicks = (cc.wifiScanTicks + 1) % 4
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    Process {
        id: depsProbe
        command: ["bash", "-lc",
            "printf 'nmcli=%s\\n' \"$(command -v nmcli >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'bluetoothctl=%s\\n' \"$(command -v bluetoothctl >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'bluetoothdevice=%s\\n' \"$(command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl list 2>/dev/null | grep -q 'Controller' && echo 1 || echo 0)\"; " +
            "printf 'brightnessctl=%s\\n' \"$(command -v brightnessctl >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'brightnessdevice=%s\\n' \"$(command -v brightnessctl >/dev/null 2>&1 && brightnessctl -l 2>/dev/null | grep -q 'backlight' && echo 1 || echo 0)\"; " +
            "printf 'ip=%s\\n' \"$(command -v ip >/dev/null 2>&1 && echo 1 || echo 0)\""
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("=")
                if (parts.length !== 2)
                    return
                const enabled = parts[1].trim() === "1"
                if (parts[0] === "nmcli")
                    cc.hasNmcli = enabled
                else if (parts[0] === "bluetoothctl")
                    cc.hasBluetoothctl = enabled
                else if (parts[0] === "bluetoothdevice")
                    cc.hasBluetoothDevice = enabled
                else if (parts[0] === "brightnessctl")
                    cc.hasBrightnessctl = enabled
                else if (parts[0] === "brightnessdevice")
                    cc.hasBrightnessDevice = enabled
                else if (parts[0] === "ip")
                    cc.hasIp = enabled
            }
        }
        onExited: refreshConnectivity()
    }

    Process {
        id: wifiStatus
        command: ["bash", "-c",
            "nmcli radio wifi; " +
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | " +
            "awk -F: '$2==\"wifi\"{print $1; print $3; print $4; found=1; exit} END{if(!found){print \"\"; print \"\"; print \"\"}}'; " +
            "nmcli -t -f active,ssid,signal,security dev wifi 2>/dev/null | " +
            "awk -F: '$1==\"yes\"{print $2; print $3; print $4; found=1; exit} END{if(!found){print \"\"; print \"\"; print \"\"}}'"]
        running: false
        stdout: SplitParser {
            property int ln: 0
            onRead: data => {
                const t = data.trim()
                if (ln === 0) cc.wifiEnabled = t === "enabled"
                else if (ln === 1) cc.wifiDevice = t
                else if (ln === 2) cc.wifiState = t
                else if (ln === 3) cc.wifiConnection = t
                else if (ln === 4) cc.wifiSsid = t
                else if (ln === 5) cc.wifiSignal = parseInt(t) || 0
                else cc.wifiSecure = t !== "" && t !== "--"
                ln++
            }
        }
        onExited: {
            wifiStatus.stdout.ln = 0
            if (!cc.wifiEnabled) {
                cc.wifiState = ""
                cc.wifiConnection = ""
                cc.wifiSsid = ""
                cc.wifiSignal = 0
                cc.wifiSecure = false
            }
        }
    }

    Process {
        id: ethernetStatus
        command: ["bash", "-c",
            "ip link show | awk '/^[0-9]+: e[a-z0-9]+:.*UP/{gsub(/:$/,\"\",$2); print $2; exit}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const iface = data.trim()
                cc.ethernetActive = iface !== ""
                cc.ethernetIface = iface
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
        running: false
        stdout: SplitParser {
            onRead: data => { cc.btEnabled = data.trim() === "yes" }
        }
    }

    Process {
        id: btScan
        command: ["bash", "-c",
            "bluetoothctl devices 2>/dev/null | head -8 | while read -r _ mac rest; do " +
            "bat=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F'[()]' '/Battery Percentage/{print $2; exit}' | tr -d '%'); " +
            "trst=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F': ' '/Trusted:/{print $2; exit}'); " +
            "conn=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F': ' '/Connected:/{print $2; exit}'); " +
            "icon=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F': ' '/Icon:/{print $2; exit}'); " +
            "printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$mac\" \"$rest\" \"$bat\" \"$trst\" \"$conn\" \"$icon\"; " +
            "done"]
        running: false
        stdout: SplitParser {
            property var devs: []
            onRead: data => {
                const line = data.trim()
                if (!line) return
                const parts = line.split("\t")
                if (parts.length < 2) return
                const mac = parts[0].trim()
                const name = parts[1].trim()
                const bRaw = (parts.length > 2 ? parts[2] : "").trim()
                const trustedRaw = (parts.length > 3 ? parts[3] : "").trim().toLowerCase()
                const connectedRaw = (parts.length > 4 ? parts[4] : "").trim().toLowerCase()
                const iconRaw = (parts.length > 5 ? parts[5] : "").trim()
                const b = parseInt(bRaw)
                if (mac && name) devs.push({
                    mac: mac,
                    name: name,
                    battery: isNaN(b) ? -1 : Math.max(0, Math.min(100, b)),
                    trusted: trustedRaw === "yes" || trustedRaw === "true",
                    connected: connectedRaw === "yes" || connectedRaw === "true",
                    iconName: iconRaw
                })
            }
        }
        onExited: {
            cc.btDevices       = btScan.stdout.devs.slice()
            const connected = cc.btDevices.filter(d => d.connected)
            cc.btConnectedCount = connected.length
            cc.btConnectedName = connected.length > 0 ? connected[0].name : ""
            cc.btConnectedIconName = connected.length > 0 ? connected[0].iconName : ""
            cc.btConnectedBattery = connected.length > 0 ? connected[0].battery : -1
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
        interval: 3000; running: cc.showing || cc.wifiManagerOpen || cc.btManagerOpen; repeat: true
        onTriggered: refreshConnectivity()
    }

    onShowingChanged: {
        if (showing) {
            refreshConnectivity()
            refreshBrightness()
        }
    }

    function openWifiManager() {
        cc.showWifiList = false
        cc.showBtList = false
        cc.showing = false
        cc.btManagerOpen = false
        cc.wifiManagerOpen = true
        refreshConnectivity()
        refreshWifiScan()
    }

    function openBtManager() {
        cc.showWifiList = false
        cc.showBtList = false
        cc.showing = false
        cc.wifiManagerOpen = false
        cc.btManagerOpen = true
        refreshConnectivity()
        refreshBtScan()
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
                color: theme.bg
                    ? Qt.tint(theme.bg, Qt.rgba(1, 1, 1, 0.08))
                    : Qt.alpha(theme.dim || "#45475a", 0.6)
                border.color: Qt.alpha(theme.dim || "#45475a", 0.45)
                border.width: 1

                Row {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                    spacing: 12
                    Rectangle {
                        width: 38; height: 38; radius: 19
                        color: Qt.alpha(theme.accent || "#89b4fa", 0.15)
                        border.color: Qt.alpha(theme.accent || "#89b4fa", 0.4); border.width: 1
                        Text {
                            anchors.centerIn: parent; text: "󰀄"; font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font Propo"; color: theme.accent || "#89b4fa"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 3
                        Text {
                            text: Quickshell.env("USER") || "user"
                            color: theme.fg || "#cdd6f4"
                            font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            text: Quickshell.env("HOSTNAME") || "localhost"
                            color: theme.muted || "#585b70"
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
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
                                font.family: "JetBrainsMono Nerd Font Propo"
                                color: btnMa.containsMouse ? modelData.hoverColor : (theme.muted || "#585b70")
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            MouseArea {
                                id: btnMa; anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: {
                                    if (modelData.cmd[0] === "hyprlock") {
                                        Quickshell.execDetached(modelData.cmd)
                                    } else if (cc.powerActions) {
                                        cc.powerActions.requestAction(
                                            modelData.cmd[1] === "reboot" ? "Restart" : "Shutdown",
                                            modelData.cmd[1] === "reboot" ? "Restart the system?" : "Power off the system?",
                                            modelData.cmd
                                        )
                                    }
                                }
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
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? "Ethernet" : "Wi-Fi"
                            color: (cc.ethernetActive || cc.wifiEnabled)
                                ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? cc.ethernetIface
                                : (cc.wifiSsid !== ""
                                    ? cc.wifiSsid + (cc.wifiSignal > 0 ? " " + cc.wifiSignal + "%" : "") + (cc.wifiSecure ? " 󰌾" : "")
                                    : cc.wifiStateLabel())
                            color: cc.ethernetActive ? (theme.muted || "#585b70") : cc.wifiStateColor()
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight; width: parent.parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    cc.openWifiManager()
                                } else {
                                    if (cc.ethernetActive) return
                                    cc.runNmcli(["radio", "wifi", cc.wifiEnabled ? "off" : "on"])
                                    refreshConnectivity()
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
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Bluetooth"
                            color: cc.btEnabled ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.btConnectedName !== ""
                                ? cc.btConnectedName + (cc.btConnectedBattery >= 0 ? " " + cc.btConnectedBattery + "%" : "")
                                : (cc.hasBluetoothDevice
                                    ? (cc.btEnabled ? "Right-click for manager" : "Off")
                                    : "No adapter")
                            color: theme.muted || "#585b70"
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight
                            width: parent.parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                cc.openBtManager()
                            } else {
                                if (!cc.hasBluetoothDevice) return
                                cc.runBluetoothctl(["power", cc.btEnabled ? "off" : "on"])
                                refreshConnectivity()
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
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "DND"
                            color: cc.dndEnabled ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.dndEnabled ? "On" : "Off"
                            color: theme.muted || "#585b70"
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (cc.notifServer) cc.notifServer.toggleDnd()
                    }
                }
            }

            // WiFi sub-list
            Column {
                width: parent.width; spacing: 3
                visible: cc.showWifiList && cc.wifiNetworks.length > 0
                Text {
                    text: "Available Networks"; color: theme.muted || "#585b70"
                    font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font Propo"; bottomPadding: 2
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
                                color: theme.accent || "#89b4fa"; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font Propo"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; text: modelData.ssid
                                color: modelData.ssid === cc.wifiSsid ? (theme.accent || "#89b4fa") : (theme.fg || "#cdd6f4")
                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                                font.weight: modelData.ssid === cc.wifiSsid ? Font.Medium : Font.Normal
                                elide: Text.ElideRight; width: parent.width - 44
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.secure; text: "󰌾"
                                color: theme.muted || "#585b70"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                        MouseArea {
                            id: wifiMa; anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                cc.runNmcli(["dev", "wifi", "connect", modelData.ssid])
                                cc.showWifiList = false
                                refreshConnectivity()
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
                    font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font Propo"; bottomPadding: 2
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
                                font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font Propo"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                                color: theme.fg || "#cdd6f4"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                                elide: Text.ElideRight; width: parent.parent.width - 50
                            }
                        }
                        MouseArea {
                            id: btMa; anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                cc.runBluetoothctl(["connect", modelData.mac])
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
                visible: cc.hasBrightnessctl && cc.hasBrightnessDevice
                height: visible ? implicitHeight : 0
                icon: "󰃞"; value: 0.5; theme: cc.theme
                onMoved: v => {
                    cc.runBrightnessctl(["set", Math.round(v * 100) + "%"])
                }
            }

            Item { width: 1; height: 6 }
        }
    }

    PanelWindow {
        id: wifiManager
        visible: cc.wifiManagerOpen

        anchors { top: true; right: true }
        margins { top: 44; right: 10 }

        implicitWidth: 320
        implicitHeight: Math.min(wifiManagerCol.implicitHeight + 24, cc.screen.height - 58)

        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Behavior on implicitHeight {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        onVisibleChanged: {
            if (visible) {
                refreshConnectivity()
                refreshWifiScan()
            }
        }

        Rectangle {
            id: wifiManagerCard
            anchors.fill: parent
            radius: 14
            color: cc.theme.bg || "#1e1e2e"
            border.color: cc.theme.dim || "#45475a"
            border.width: 1
            clip: true
            opacity: cc.wifiManagerOpen ? 1 : 0

            transform: Translate {
                y: cc.wifiManagerOpen ? 0 : -14
                Behavior on y {
                    NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Column {
                id: wifiManagerCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8

                Row {
                    width: parent.width
                    height: 24
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wi-Fi Manager"
                        color: cc.theme.fg || "#cdd6f4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.Medium
                    }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: "✕"
                        color: wifiCloseMa.containsMouse ? (cc.theme.red || "#f38ba8") : (cc.theme.muted || "#585b70")
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font Propo"
                        MouseArea {
                            id: wifiCloseMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.wifiManagerOpen = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: btPowerMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.16)
                        : Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                    border.color: btPowerMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.38)
                        : Qt.alpha(cc.theme.accent || "#89b4fa", 0.22)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.wifiEnabled ? "󰤨" : "󰤭"
                            color: cc.wifiEnabled ? (cc.theme.accent || "#89b4fa") : (cc.theme.muted || "#585b70")
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.wifiEnabled
                                ? (cc.wifiSsid !== ""
                                    ? cc.wifiSsid + (cc.wifiSignal > 0 ? "  " + cc.wifiSignal + "%" : "")
                                    : cc.wifiStateLabel())
                                : "Wi-Fi Off"
                            color: cc.theme.fg || "#cdd6f4"
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.wifiEnabled ? "Disable" : "Enable"
                            color: cc.theme.accent || "#89b4fa"
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cc.runNmcli(["radio", "wifi", cc.wifiEnabled ? "off" : "on"])
                            refreshConnectivity()
                            refreshWifiScan()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: Qt.alpha(cc.theme.dim || "#45475a", 0.18)
                    border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.3)
                    border.width: 1
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: "Rescan Networks"
                            color: cc.theme.muted || "#585b70"
                            font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 6
                            Row {
                                visible: cc.wifiScanning
                                spacing: 2
                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        width: 4; height: 4; radius: 2
                                        color: cc.theme.accent || "#89b4fa"
                                        opacity: cc.wifiScanTicks === (index + 1) ? 1 : 0.25
                                    }
                                }
                            }
                            Text {
                                text: cc.wifiScanning ? "Scanning" : "Scan"
                                color: cc.theme.accent || "#89b4fa"
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cc.runNmcli(["dev", "wifi", "rescan"])
                            refreshConnectivity()
                            refreshWifiScan()
                            cc.wifiScanning = true
                            cc.wifiScanTicks = 0
                            wifiRescanTimer.restart()
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: 270
                    contentHeight: wifiListCol.implicitHeight
                    clip: true

                    Column {
                        id: wifiListCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: cc.wifiNetworks
                            delegate: Rectangle {
                                required property var modelData
                                width: wifiListCol.width
                                height: 34
                                radius: 8
                                color: wifiMgrItemMa.containsMouse
                                    ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.12)
                                    : Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                                border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                                border.width: 1

                                Row {
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 }
                                    spacing: 8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.signal > 66 ? "󰤨" : modelData.signal > 33 ? "󰤢" : "󰤟"
                                        color: cc.theme.accent || "#89b4fa"
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ssid
                                        color: modelData.ssid === cc.wifiSsid ? (cc.theme.accent || "#89b4fa") : (cc.theme.fg || "#cdd6f4")
                                        font.pixelSize: 10
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        elide: Text.ElideRight
                                        width: parent.width - 86
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.ssid === cc.wifiSsid && cc.wifiState !== "" ? cc.wifiState : (modelData.secure ? "secure" : "")
                                        color: modelData.ssid === cc.wifiSsid ? cc.wifiStateColor() : (cc.theme.muted || "#585b70")
                                        font.pixelSize: 8
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                    }
                                }

                                MouseArea {
                                    id: wifiMgrItemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cc.runNmcli(["dev", "wifi", "connect", modelData.ssid])
                                        refreshConnectivity()
                                        refreshWifiScan()
                                    }
                                }
                            }
                        }

                        Item {
                            visible: cc.wifiNetworks.length === 0
                            width: parent.width
                            height: 56
                            Text {
                                anchors.centerIn: parent
                                text: "No networks found"
                                color: cc.theme.muted || "#585b70"
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: btManager
        visible: cc.btManagerOpen

        anchors { top: true; right: true }
        margins { top: 44; right: 10 }

        implicitWidth: 320
        implicitHeight: Math.min(btManagerCol.implicitHeight + 24, cc.screen.height - 58)

        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Behavior on implicitHeight {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        onVisibleChanged: {
            if (visible) {
                refreshConnectivity()
                refreshBtScan()
            }
        }

        Rectangle {
            id: btManagerCard
            anchors.fill: parent
            radius: 14
            color: cc.theme.bg || "#1e1e2e"
            border.color: cc.theme.dim || "#45475a"
            border.width: 1
            clip: true
            opacity: cc.btManagerOpen ? 1 : 0

            transform: Translate {
                y: cc.btManagerOpen ? 0 : -14
                Behavior on y {
                    NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Column {
                id: btManagerCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8

                Row {
                    width: parent.width
                    height: 24
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Bluetooth Manager"
                        color: cc.theme.fg || "#cdd6f4"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.Medium
                    }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: "✕"
                        color: btCloseMa.containsMouse ? (cc.theme.red || "#f38ba8") : (cc.theme.muted || "#585b70")
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font Propo"
                        MouseArea {
                            id: btCloseMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.btManagerOpen = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                    border.color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.22)
                    border.width: 1
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.btEnabled ? "󰂱" : "󰂲"
                            color: cc.btEnabled ? (cc.theme.accent || "#89b4fa") : (cc.theme.muted || "#585b70")
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.hasBluetoothDevice
                                ? (cc.btEnabled ? "Bluetooth On" : "Bluetooth Off")
                                : "Bluetooth adapter not found"
                            color: cc.theme.fg || "#cdd6f4"
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.hasBluetoothDevice ? (cc.btEnabled ? "Disable" : "Enable") : ""
                            color: cc.theme.accent || "#89b4fa"
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                    MouseArea {
                        id: btPowerMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: cc.hasBluetoothDevice
                        onClicked: {
                            cc.runBluetoothctl(["power", cc.btEnabled ? "off" : "on"])
                            refreshConnectivity()
                            refreshBtScan()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: btScanMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.14)
                        : Qt.alpha(cc.theme.dim || "#45475a", 0.18)
                    border.color: btScanMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.32)
                        : Qt.alpha(cc.theme.dim || "#45475a", 0.3)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.hasBluetoothDevice ? "Scan nearby devices" : "No Bluetooth adapter found"
                            color: cc.hasBluetoothDevice ? (cc.theme.muted || "#585b70") : (cc.theme.red || "#f38ba8")
                            font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 6
                            Row {
                                visible: cc.hasBluetoothDevice && cc.btScanning
                                spacing: 2
                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        width: 4; height: 4; radius: 2
                                        color: cc.theme.accent || "#89b4fa"
                                        opacity: cc.btScanTicks === (index + 1) ? 1 : 0.25
                                    }
                                }
                            }
                            Text {
                                text: cc.hasBluetoothDevice ? (cc.btScanning ? "Scanning" : "Scan") : ""
                                color: cc.theme.accent || "#89b4fa"
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                    }
                    MouseArea {
                        id: btScanMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: cc.hasBluetoothDevice
                        onClicked: {
                            if (cc.hasBluetoothctl)
                                Quickshell.execDetached(["bash", "-lc", "bluetoothctl --timeout 6 scan on >/dev/null 2>&1"])
                            if (!cc.btScanning) {
                                cc.btScanning = true
                                cc.btScanTicks = 0
                                btRescanTimer.restart()
                            }
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: 270
                    contentHeight: btListCol.implicitHeight
                    clip: true

                    Column {
                        id: btListCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: cc.btDevices
                            delegate: Rectangle {
                                required property var modelData
                                width: btListCol.width
                                height: 62
                                radius: 8
                                color: btMgrItemMa.containsMouse
                                    ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.12)
                                    : Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                                border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.topMargin: 8
                                    anchors.bottomMargin: 8
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: "󰂯"
                                            color: cc.theme.accent || "#89b4fa"
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            text: modelData.name
                                            color: cc.theme.fg || "#cdd6f4"
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            visible: modelData.battery >= 0
                                            text: "󰁹 " + modelData.battery + "%"
                                            color: cc.theme.muted || "#585b70"
                                            font.pixelSize: 9
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: modelData.connected ? "connected" : (modelData.trusted ? "trusted" : "untrusted")
                                            color: modelData.connected
                                                ? (cc.theme.accent || "#89b4fa")
                                                : modelData.trusted
                                                    ? (cc.theme.green || "#a6e3a1")
                                                    : (cc.theme.red || "#f38ba8")
                                            font.pixelSize: 8
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            width: actConnect.implicitWidth + 10
                                            height: 18
                                            radius: 9
                                            visible: !modelData.connected
                                            color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.16)
                                            Text {
                                                id: actConnect
                                                anchors.centerIn: parent
                                                text: "connect"
                                                color: cc.theme.accent || "#89b4fa"
                                                font.pixelSize: 8
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    cc.runBluetoothctl(["connect", modelData.mac])
                                                    refreshConnectivity()
                                                }
                                            }
                                        }
                                        Rectangle {
                                            width: actDisconnect.implicitWidth + 10
                                            height: 18
                                            radius: 9
                                            visible: modelData.connected
                                            color: Qt.alpha("#fab387", 0.16)
                                            Text {
                                                id: actDisconnect
                                                anchors.centerIn: parent
                                                text: "disconnect"
                                                color: "#fab387"
                                                font.pixelSize: 8
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    cc.runBluetoothctl(["disconnect", modelData.mac])
                                                    refreshConnectivity()
                                                }
                                            }
                                        }
                                        Rectangle {
                                            width: actRemove.implicitWidth + 10
                                            height: 18
                                            radius: 9
                                            color: Qt.alpha(cc.theme.red || "#f38ba8", 0.16)
                                            Text {
                                                id: actRemove
                                                anchors.centerIn: parent
                                                text: "remove"
                                                color: cc.theme.red || "#f38ba8"
                                                font.pixelSize: 8
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    cc.runBluetoothctl(["remove", modelData.mac])
                                                    refreshConnectivity()
                                                }
                                            }
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: btMgrItemMa
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }

                        Rectangle {
                            visible: cc.btDevices.length === 0
                            width: parent.width
                            height: 76
                            radius: 8
                            color: Qt.alpha(cc.theme.dim || "#45475a", 0.18)
                            border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                            border.width: 1
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: cc.hasBluetoothDevice ? "No devices found" : "Bluetooth adapter not detected"
                                    color: cc.hasBluetoothDevice ? (cc.theme.fg || "#cdd6f4") : (cc.theme.red || "#f38ba8")
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: cc.hasBluetoothDevice ? "Click Scan to discover" : "Enable Bluetooth in system"
                                    color: cc.theme.muted || "#585b70"
                                    font.pixelSize: 9
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
