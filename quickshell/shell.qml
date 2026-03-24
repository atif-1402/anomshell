//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "bar"
import "bar/modules"
import "launcher"

ShellRoot {
    id: shell

    property string bg:        "#1e1e2e"
    property string fg:        "#cdd6f4"
    property string accent:    "#89b4fa"
    property string dim:       "#45475a"
    property string highlight: "#cba6f7"
    property string red:       "#f38ba8"
    property string green:     "#a6e3a1"
    property string muted:     "#585b70"

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
        command: ["cat", "/home/atif/.config/omarchy/current/theme/colors.toml"]
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
    command: ["inotifywait", "-m", "-e", "close_write",
              "/home/atif/.config/omarchy/current/theme.name"]
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
    }

    Launcher {
        id: appLauncher
        theme: ({
            bg:        shell.bg,
            fg:        shell.fg,
            accent:    shell.accent,
            dim:       shell.dim,
            muted:     shell.muted,
            highlight: shell.highlight
        })
    }

    ThemePicker {
        id: themePicker
        theme: ({
            bg:        shell.bg,
            fg:        shell.fg,
            accent:    shell.accent,
            dim:       shell.dim,
            muted:     shell.muted,
            highlight: shell.highlight
        })
    }

    KeybindViewer {
        id: keybindViewer
        theme: ({
            bg:        shell.bg,
            fg:        shell.fg,
            accent:    shell.accent,
            dim:       shell.dim,
            muted:     shell.muted,
            highlight: shell.highlight
        })
    }
    
    NotificationPanel {
        theme: ({
            bg:        shell.bg,
            fg:        shell.fg,
            accent:    shell.accent,
            dim:       shell.dim,
            muted:     shell.muted,
            highlight: shell.highlight,
            red:       shell.red,
            green:     shell.green
        })
    }

    NotificationServer {
        id: notifServer
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

    // Click Catcher Here 
    ClickCatcher {
        active: appLauncher.showing || themePicker.showing || keybindViewer.showing || NotificationServer.panelOpen
        onClicked: {
            appLauncher.showing   = false
            themePicker.showing   = false
            keybindViewer.showing = false
            NotificationServer.panelOpen = false
        }
    }

}