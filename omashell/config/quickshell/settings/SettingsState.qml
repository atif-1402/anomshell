import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configDir: homeDir + "/.config/quickshell"
    readonly property string settingsDir: configDir + "/settings"
    property string notificationPosition: "top-center"
    property string osdPosition: "bottom-center"
    property string barPosition: "top"
    property string barStyle: "dock"
    property string workspaceStyle: "og"
    property string launcherIconPreset: "command"
    property int launcherIconSize: 12
    property bool rememberSettingsWindowPosition: false
    property bool openSettingsOnGeneralAlways: true
    property bool loaded: false
    property string settingsPath: settingsDir + "/settings.json"
    property int saveDelayMs: 500
    readonly property var defaults: ({
        notificationPosition: "top-center",
        osdPosition: "bottom-center",
        barPosition: "top",
        barStyle: "dock",
        workspaceStyle: "og",
        launcherIconPreset: "command",
        launcherIconSize: 12,
        rememberSettingsWindowPosition: false,
        openSettingsOnGeneralAlways: true
    })

    function _applyDefaults() {
        notificationPosition = defaults.notificationPosition
        osdPosition = defaults.osdPosition
        barPosition = defaults.barPosition
        barStyle = defaults.barStyle
        workspaceStyle = defaults.workspaceStyle
        launcherIconPreset = defaults.launcherIconPreset
        launcherIconSize = defaults.launcherIconSize
        rememberSettingsWindowPosition = defaults.rememberSettingsWindowPosition
        openSettingsOnGeneralAlways = defaults.openSettingsOnGeneralAlways
    }

    function _apply(raw) {
        try {
            const data = JSON.parse(raw || "{}")
            if (data.notificationPosition)
                notificationPosition = data.notificationPosition
            if (data.osdPosition)
                osdPosition = data.osdPosition
            if (data.barPosition)
                barPosition = data.barPosition
            if (data.barStyle) {
                if (data.barStyle === "flat")
                    barStyle = "flat"
                else
                    barStyle = "dock"
            }
            if (data.workspaceStyle) {
                if (data.workspaceStyle === "pills")
                    workspaceStyle = "strip"
                else if (["og", "strip", "pulse"].includes(data.workspaceStyle))
                    workspaceStyle = data.workspaceStyle
            }
            if (data.launcherIconPreset)
                launcherIconPreset = data.launcherIconPreset
            if (typeof data.launcherIconSize === "number")
                launcherIconSize = Math.max(10, Math.min(18, Math.round(data.launcherIconSize)))
            if (typeof data.rememberSettingsWindowPosition === "boolean")
                rememberSettingsWindowPosition = data.rememberSettingsWindowPosition
            if (typeof data.openSettingsOnGeneralAlways === "boolean")
                openSettingsOnGeneralAlways = data.openSettingsOnGeneralAlways
        } catch (e) {
            // keep defaults when the file is missing or malformed
            _applyDefaults()
        }
        loaded = true
    }

    function _writeSettings() {
        const payload = JSON.stringify({
            notificationPosition: notificationPosition,
            osdPosition: osdPosition,
            barPosition: barPosition,
            barStyle: barStyle,
            workspaceStyle: workspaceStyle,
            launcherIconPreset: launcherIconPreset,
            launcherIconSize: launcherIconSize,
            rememberSettingsWindowPosition: rememberSettingsWindowPosition,
            openSettingsOnGeneralAlways: openSettingsOnGeneralAlways
        }, null, 2)

        Quickshell.execDetached([
            "bash",
            "-lc",
            "mkdir -p " + root.settingsDir + " && tmp=" + root.settingsPath + ".tmp && cat > \"$tmp\" <<'EOF'\n" +
            payload +
            "\nEOF\nmv \"$tmp\" " + root.settingsPath
        ])
    }

    function resetToDefaults() {
        _applyDefaults()
        if (loaded) {
            saveTimer.stop()
            _writeSettings()
        }
    }

    function save() {
        if (!loaded)
            return
        saveTimer.restart()
    }

    onNotificationPositionChanged: save()
    onOsdPositionChanged: save()
    onBarPositionChanged: save()
    onBarStyleChanged: save()
    onWorkspaceStyleChanged: save()
    onLauncherIconPresetChanged: save()
    onLauncherIconSizeChanged: save()
    onRememberSettingsWindowPositionChanged: save()
    onOpenSettingsOnGeneralAlwaysChanged: save()

    Timer {
        id: saveTimer
        interval: root.saveDelayMs
        repeat: false
        onTriggered: root._writeSettings()
    }

    Process {
        id: loader
        command: ["bash", "-lc", "cat " + root.settingsPath + " 2>/dev/null"]
        running: true
        stdout: SplitParser {
            property string buf: ""
            onRead: data => buf += data + "\n"
        }
        onExited: {
            const raw = loader.stdout && loader.stdout.buf ? loader.stdout.buf : ""
            root._apply(raw)
            loader.stdout.buf = ""
        }
    }
}
