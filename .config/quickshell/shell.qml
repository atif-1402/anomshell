//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "bar"
import "bar/modules"
import "settings"
import "launcher"

ShellRoot {
    id: shell

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string omarchyCurrentDir: homeDir + "/.config/omarchy/current"
    readonly property string omarchyThemeNamePath: omarchyCurrentDir + "/theme.name"
    readonly property string omarchyThemeColorsPath: omarchyCurrentDir + "/theme/colors.toml"

    property string bg:        "#1e1e2e"
    property string fg:        "#cdd6f4"
    property string accent:    "#89b4fa"
    property string dim:       "#45475a"
    property string highlight: "#cba6f7"
    property string red:       "#f38ba8"
    property string green:     "#a6e3a1"
    property string muted:     "#585b70"
    readonly property var palette: ({
        bg:        shell.bg,
        fg:        shell.fg,
        accent:    shell.accent,
        dim:       shell.dim,
        muted:     shell.muted,
        highlight: shell.highlight,
        red:       shell.red,
        green:     shell.green
    })

    SettingsState {
        id: settingsState
    }

    QtObject {
        id: powerActions

        property bool open: false
        property string title: ""
        property string message: ""
        property var command: null
        property int selectedIndex: 0

        function requestAction(titleText, messageText, cmd) {
            title = titleText
            message = messageText
            command = cmd
            selectedIndex = 0
            open = true
        }

        function close() {
            open = false
            command = null
            selectedIndex = 0
        }

        function moveSelection(delta) {
            selectedIndex = (selectedIndex + delta + 2) % 2
        }

        function activateSelected() {
            if (selectedIndex === 0) close()
            else confirm()
        }

        function confirm() {
            if (!command) {
                close()
                return
            }

            if (Array.isArray(command))
                Quickshell.execDetached(command)
            else
                Quickshell.execDetached(["bash", "-lc", command])

            close()
        }
    }

    function parseToml(raw) {
        function get(key) {
            const rx = new RegExp('(?:^|\\n)' + key + '\\s*=\\s*"(#[0-9a-fA-F]{3,8})"')
            const m  = raw.match(rx)
            return m ? m[1] : null
        }
        bg        = get("background") || bg
        fg        = get("foreground") || fg
        accent    = get("accent")     || accent
        dim       = get("color0")     || dim
        muted     = get("color8")     || muted
        highlight = get("color5")     || highlight
        red       = get("color1")     || red
        green     = get("color2")     || green
    }

    Process {
        id: themeLoader
        command: ["bash", "-lc", "cat " + shell.omarchyThemeColorsPath + " 2>/dev/null"]
        running: true
        stdout: SplitParser {
            property string buf: ""
            onRead: data => buf += data + "\n"
        }
        onExited: {
            if (themeLoader.stdout.buf.length > 10)
                parseToml(themeLoader.stdout.buf)
            themeLoader.stdout.buf = ""
        }
    }

    Process {
        id: themeWatcher
        command: ["bash", "-lc",
            "if command -v inotifywait >/dev/null 2>&1; then " +
            "  exec inotifywait -m -e close_write " + shell.omarchyThemeNamePath + "; " +
            "else " +
            "  last=''; " +
            "  while true; do " +
            "    cur=$(stat -c %Y " + shell.omarchyThemeNamePath + " 2>/dev/null || echo missing); " +
            "    if [ \"$cur\" != \"$last\" ]; then printf 'changed\\n'; last=\"$cur\"; fi; " +
            "    sleep 3; " +
            "  done; " +
            "fi"
        ]
        running: true
        stdout: SplitParser {
            onRead: _ => {
                themeLoader.stdout.buf = ""
                themeLoader.running = false
                themeLoader.running = true
            }
        }
    }

    Bar {
        launcher:  appLauncher
        notifServer: notifServer
        powerActions: powerActions
        settings: settingsState
        bg:        shell.bg
        fg:        shell.fg
        accent:    shell.accent
        dim:       shell.dim
        highlight: shell.highlight
        red:       shell.red
        green:     shell.green
        muted:     shell.muted
    }

    ControlCenter {
        id: controlCenter
        theme: shell.palette
        notifServer: notifServer
        powerActions: powerActions
        settingsWindow: settingsWindow
    }

    Launcher {
        id: appLauncher
        theme: shell.palette
        powerActions: powerActions
    }

    ThemePicker {
        id: themePicker
        theme: shell.palette
    }

    BgPicker {
        id: bgPicker
        theme: shell.palette
    }

    KeybindViewer {
        id: keybindViewer
        theme: shell.palette
    }

    Clipboard {
        id: clipboardManager
        theme: shell.palette
    }

    SettingsWindow {
        id: settingsWindow
        theme: shell.palette
        state: settingsState
    }
    
    NotificationPanel {
        theme: shell.palette
        settings: settingsState
    }

    OsdService {
        id: osdService
    }

    Osd {
        service: osdService
        settings: settingsState
        theme: shell.palette
    }

    NotificationServer {
        id: notifServer
    }

    IpcHandler {
        target: "openSettings"
        function handle() {
            settingsWindow.showing = true
        }
    }

    PanelWindow {
        id: powerConfirm
        visible: powerActions.open
        color: "transparent"
        anchors { top: true; left: true; right: true; bottom: true }
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        onVisibleChanged: {
            if (visible)
                powerConfirm.forceActiveFocus()
        }

        Keys.onPressed: event => {
            if (!powerActions.open) return

            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                powerActions.moveSelection(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                powerActions.moveSelection(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                powerActions.activateSelected()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                powerActions.close()
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: powerActions.close()

            Rectangle {
                id: powerConfirmCard
                width: 320
                implicitHeight: contentColumn.implicitHeight + 32
                radius: 14
                color: shell.bg
                border.color: shell.dim
                border.width: 1
                anchors.centerIn: parent
                opacity: powerActions.open ? 1 : 0
                scale: powerActions.open ? 1 : 0.96

                Behavior on opacity {
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }

                Behavior on scale {
                    NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: powerActions.title
                        color: shell.fg
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: powerActions.message
                        color: shell.muted
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font Propo"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            id: cancelButton
                            Layout.fillWidth: true
                            height: 32
                            radius: 9
                            color: powerActions.selectedIndex === 0
                                ? Qt.alpha(shell.accent, 0.16)
                                : Qt.alpha(shell.dim, 0.45)
                            border.color: powerActions.selectedIndex === 0
                                ? Qt.alpha(shell.accent, 0.5)
                                : Qt.alpha(shell.dim, 0.7)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: powerActions.selectedIndex === 0 ? shell.accent : shell.fg
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: powerActions.selectedIndex = 0
                                onClicked: powerActions.close()
                            }
                        }

                        Rectangle {
                            id: confirmButton
                            Layout.fillWidth: true
                            height: 32
                            radius: 9
                            color: powerActions.selectedIndex === 1
                                ? Qt.alpha(shell.red, 0.28)
                                : Qt.alpha(shell.red, 0.2)
                            border.color: powerActions.selectedIndex === 1
                                ? Qt.alpha(shell.red, 0.72)
                                : Qt.alpha(shell.red, 0.45)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm"
                                color: powerActions.selectedIndex === 1 ? shell.fg : shell.red
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: powerActions.selectedIndex = 1
                                onClicked: powerActions.confirm()
                            }
                        }
                    }
                }
            }
        }
    }

    // ALL IpcHandler here for keybinds 
    IpcHandler {
        target: "openKeybindings"
        function handle() {
            keybindViewer.showing = true
        }
    }

    IpcHandler {
        target: "openMenu"
        function handle() {
            appLauncher.mode    = "menu"
            appLauncher.showing = true
        }
    }

    IpcHandler {
        target: "openApps"
        function handle() {
            appLauncher.mode          = "apps"
            appLauncher.appSearchText = ""
            appLauncher.showing       = true
        }
    }

    IpcHandler {
        target: "openThemes"
        function handle() {
            themePicker.showing = true
        }
    }

    IpcHandler {
        target: "openThemePicker"
        function handle() {
            themePicker.showing = true
        }
    }

    IpcHandler {
        target: "openBackgroundPicker"
        function handle() {
            bgPicker.showing = true
        }
    }

    IpcHandler {
        target: "openScreenrecord"
        function handle() {
            appLauncher.openScreenrecord()
        }
    }

    IpcHandler {
        target: "openSystem"
        function handle() {
            appLauncher.openSystem()
        }
    }

    IpcHandler {
        target: "openClipboard"
        function handle() {
            clipboardManager.showing = true
        }
    }

    IpcHandler {
        target: "toggleDnd"
        function handle() {
            notifServer.toggleDnd()
        }
    }

    IpcHandler {
        target: "osdVolume"
        function handle() {
            osdService.showVolume()
        }
    }

    IpcHandler {
        target: "osdVolumeUp"
        function handle() {
            osdService.volumeStep(5)
        }
    }

    IpcHandler {
        target: "osdVolumeDown"
        function handle() {
            osdService.volumeStep(-5)
        }
    }

    IpcHandler {
        target: "osdVolumeMute"
        function handle() {
            osdService.toggleMute()
        }
    }

    IpcHandler {
        target: "osdBrightness"
        function handle() {
            osdService.showBrightness()
        }
    }

    IpcHandler {
        target: "osdBrightnessUp"
        function handle() {
            osdService.brightnessStep(5)
        }
    }

    IpcHandler {
        target: "osdBrightnessDown"
        function handle() {
            osdService.brightnessStep(-5)
        }
    }

    IpcHandler {
        target: "osdMic"
        function handle() {
            osdService.showMic()
        }
    }

    IpcHandler {
        target: "osdMedia"
        function handle() {
            osdService.showMediaStatus()
        }
    }

    IpcHandler {
        target: "osdMediaPlayPause"
        function handle() {
            osdService.mediaPlayPause()
        }
    }

    IpcHandler {
        target: "osdMediaNext"
        function handle() {
            osdService.mediaNext()
        }
    }

    IpcHandler {
        target: "osdMediaPrev"
        function handle() {
            osdService.mediaPrev()
        }
    }

    // Click Catcher Here 
    ClickCatcher {
        active: appLauncher.showing
            || themePicker.showing
            || bgPicker.showing
            || keybindViewer.showing
            || clipboardManager.showing
            || notifServer.panelOpen
            || controlCenter.showing
            || controlCenter.wifiManagerOpen
            || controlCenter.btManagerOpen
        onClicked: {
            appLauncher.showing   = false
            themePicker.showing   = false
            bgPicker.showing      = false
            keybindViewer.showing = false
            clipboardManager.showing = false
            notifServer.panelOpen = false
            controlCenter.showing = false
            controlCenter.wifiManagerOpen = false
            controlCenter.btManagerOpen = false
        }
    }

}
