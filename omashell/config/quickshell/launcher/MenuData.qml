pragma Singleton
import QtQuick

QtObject {
    id: root

    function buildTree() {
        return [
            {
                icon: "󰀻", label: "Apps",
                action: "apps"
            },
            {
                icon: "󰧑", label: "Learn",
                children: [
                    { icon: "󰌌",  label: "Keybindings", action: "openKeybindings" },
                    { icon: "<span font='omarchy'>\ue900</span>",  label: "Omarchy",     cmd: "omarchy-launch-webapp https://learn.omacom.io/2/the-omarchy-manual" },
                    { icon: "",  label: "Hyprland",    cmd: "omarchy-launch-webapp https://wiki.hypr.land/" },
                    { icon: "󰣇", label: "Arch",        cmd: "omarchy-launch-webapp https://wiki.archlinux.org/title/Main_page" },
                    { icon: "",  label: "Neovim",      cmd: "omarchy-launch-webapp https://www.lazyvim.org/keymaps" },
                    { icon: "󱆃", label: "Bash",        cmd: "omarchy-launch-webapp https://devhints.io/bash" },
                ]
            },
            {
                icon: "󱓞", label: "Trigger",
                children: [
                    {
                        icon: "", label: "Capture",
                        children: [
                            { icon: "",  label: "Screenshot",   cmd: "omarchy-cmd-screenshot" },
                            {
                                icon: "", label: "Screenrecord",
                                children: [
                                    { icon: "", label: "No audio",               cmd: "nohup omarchy-cmd-screenrecord </dev/null >/dev/null 2>&1 &" },
                                    { icon: "", label: "Desktop audio",          cmd: "nohup omarchy-cmd-screenrecord --with-desktop-audio </dev/null >/dev/null 2>&1 &" },
                                    { icon: "", label: "Desktop + microphone",   cmd: "nohup omarchy-cmd-screenrecord --with-desktop-audio --with-microphone-audio </dev/null >/dev/null 2>&1 &" },
                                    { icon: "", label: "Desktop + mic + webcam", cmd: "nohup omarchy-cmd-screenrecord --with-desktop-audio --with-microphone-audio --with-webcam </dev/null >/dev/null 2>&1 &" },
                                ]
                            },
                            { icon: "󰴱", label: "Color Picker", cmd: "pkill hyprpicker || hyprpicker -a" },
                        ]
                    },
                    {
                        icon: "", label: "Share",
                        children: [
                            { icon: "", label: "Clipboard", cmd: "omarchy-cmd-share clipboard" },
                            { icon: "", label: "File",      cmd: "xdg-terminal-exec --app-id=org.omarchy.terminal bash -c 'omarchy-cmd-share file'" },
                            { icon: "", label: "Folder",    cmd: "xdg-terminal-exec --app-id=org.omarchy.terminal bash -c 'omarchy-cmd-share folder'" },
                        ]
                    },
                    {
                        icon: "󰔎", label: "Toggle",
                        children: [
                            { icon: "󱄄", label: "Screensaver",     cmd: "omarchy-toggle-screensaver" },
                            { icon: "󰔎", label: "Nightlight",       cmd: "omarchy-toggle-nightlight" },
                            { icon: "󱫖", label: "Idle Lock",        cmd: "omarchy-toggle-idle" },
                            { icon: "󰍜", label: "Top Bar",          cmd: "omarchy-toggle-waybar" },
                            { icon: "󱂬", label: "Workspace Layout", cmd: "omarchy-hyprland-workspace-layout-toggle" },
                            { icon: "",  label: "Window Gaps",      cmd: "omarchy-hyprland-window-gaps-toggle" },
                            { icon: "",  label: "1-Window Ratio",   cmd: "omarchy-hyprland-window-single-square-aspect-toggle" },
                            { icon: "󰍹", label: "Display Scaling",  cmd: "omarchy-hyprland-monitor-scaling-cycle" },
                        ]
                    },
                    {
                        icon: "", label: "Hardware",
                        children: [
                            { icon: "", label: "Hybrid GPU", terminal: "omarchy-toggle-hybrid-gpu" },
                        ]
                    },
                ]
            },
            {
                icon: "", label: "Style",
                children: [
                    { icon: "󰸌", label: "Theme", action: "openThemes" },
                    { icon: "󰛖",  label: "Font",        cmd: "omarchy-launch-walker -m menus:omarchythemes --width 800 --minheight 400" },
                    { icon: "",  label: "Background",  cmd: "omarchy-launch-walker -m menus:omarchyBackgroundSelector --width 800 --minheight 400" },
                    { icon: "",  label: "Hyprland",    cmd: "omarchy-launch-editor ~/.config/hypr/looknfeel.conf" },
                    { icon: "󱄄", label: "Screensaver", cmd: "omarchy-launch-editor ~/.config/omarchy/branding/screensaver.txt" },
                    { icon: "",  label: "About",       cmd: "omarchy-launch-editor ~/.config/omarchy/branding/about.txt" },
                ]
            },
            {
                icon: "", label: "Setup",
                children: [
                    { icon: "",  label: "Audio",       cmd: "omarchy-launch-audio" },
                    { icon: "󰖩",  label: "Wifi",        cmd: "omarchy-launch-wifi" },
                    { icon: "󰂯", label: "Bluetooth",   cmd: "omarchy-launch-bluetooth" },
                    { icon: "󱐋", label: "Power Profile", cmd: "omarchy-launch-walker -m menus:omarchyPowerProfiles --width 400 --minheight 1" },
                    {
                        icon: "⏼", label: "System Sleep",
                        children: [
                            { icon: "󰒲", label: "Toggle Suspend",   cmd: "omarchy-toggle-suspend" },
                            { icon: "󰤁", label: "Setup Hibernate",  terminal: "omarchy-hibernation-setup" },
                            { icon: "󰤁", label: "Remove Hibernate", terminal: "omarchy-hibernation-remove" },
                        ]
                    },
                    { icon: "󰍹", label: "Monitors",    cmd: "omarchy-launch-editor ~/.config/hypr/monitors.conf" },
                    { icon: "󰌌",  label: "Keybindings", cmd: "omarchy-launch-editor ~/.config/hypr/bindings.conf" },
                    { icon: "󱡫",  label: "Input",       cmd: "omarchy-launch-editor ~/.config/hypr/input.conf" },
                    { icon: "󰱔", label: "DNS",         terminal: "omarchy-setup-dns" },
                    {
                        icon: "󰒃", label: "Security",
                        children: [
                            { icon: "󰈷", label: "Fingerprint", terminal: "omarchy-setup-fingerprint" },
                            { icon: "󰯄",  label: "Fido2",        terminal: "omarchy-setup-fido2" },
                        ]
                    },
                    {
                        icon: "", label: "Config",
                        children: [
                            { icon: "", label: "Defaults",   cmd: "omarchy-launch-editor ~/.config/uwsm/default" },
                            { icon: "", label: "Hyprland",   cmd: "omarchy-launch-editor ~/.config/hypr/hyprland.conf" },
                            { icon: "", label: "Hypridle",   cmd: "omarchy-launch-editor ~/.config/hypr/hypridle.conf" },
                            { icon: "", label: "Hyprlock",   cmd: "omarchy-launch-editor ~/.config/hypr/hyprlock.conf" },
                            { icon: "", label: "Hyprsunset", cmd: "omarchy-launch-editor ~/.config/hypr/hyprsunset.conf" },
                            { icon: "", label: "Swayosd",    cmd: "omarchy-launch-editor ~/.config/swayosd/config.toml" },
                            { icon: "󰍜", label: "Walker",     cmd: "omarchy-launch-editor ~/.config/walker/config.toml" },
                            { icon: "󱔓", label: "Waybar",     cmd: "omarchy-launch-editor ~/.config/waybar/config.jsonc" },
                            { icon: "󰞅", label: "XCompose",   cmd: "omarchy-launch-editor ~/.XCompose" },
                        ]
                    },
                ]
            },
            {
                icon: "󰉉", label: "Install",
                children: [
                    { icon: "󰣇", label: "Package",  cmd: "xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-install" },
                    { icon: "󰣇", label: "AUR",       cmd: "xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-aur-install" },
                    { icon: "󰖟",  label: "Web App",   terminal: "omarchy-webapp-install" },
                    { icon: "󰆧",  label: "TUI",       terminal: "omarchy-tui-install" },
                    {
                        icon: "", label: "Service",
                        children: [
                            { icon: "",  label: "Dropbox",          terminal: "omarchy-install-dropbox" },
                            { icon: "󰆧",  label: "Tailscale",        terminal: "omarchy-install-tailscale" },
                            { icon: "󱇱", label: "NordVPN",          terminal: "omarchy-install-nordvpn" },
                            { icon: "󰟵", label: "Bitwarden",        terminal: "omarchy-pkg-add bitwarden bitwarden-cli" },
                            { icon: "",  label: "Chromium Account", terminal: "omarchy-install-chromium-google-account" },
                        ]
                    },
                    {
                        icon: "", label: "Style",
                        children: [
                            { icon: "󰸌", label: "Theme",      terminal: "omarchy-theme-install" },
                            { icon: "",  label: "Background",  cmd: "omarchy-theme-bg-install" },
                            {
                                icon: "󰛖", label: "Font",
                                children: [
                                    { icon: "󰛖", label: "Cascadia Mono",  terminal: "omarchy-pkg-add ttf-cascadia-mono-nerd && omarchy-font-set 'CaskaydiaMono Nerd Font'" },
                                    { icon: "󰛖", label: "Meslo LG Mono",  terminal: "omarchy-pkg-add ttf-meslo-nerd && omarchy-font-set 'MesloLGL Nerd Font'" },
                                    { icon: "󰛖", label: "Fira Code",      terminal: "omarchy-pkg-add ttf-firacode-nerd && omarchy-font-set 'FiraCode Nerd Font'" },
                                    { icon: "󰛖", label: "Victor Mono",    terminal: "omarchy-pkg-add ttf-victor-mono-nerd && omarchy-font-set 'VictorMono Nerd Font'" },
                                    { icon: "󰛖", label: "Bitstream Vera", terminal: "omarchy-pkg-add ttf-bitstream-vera-mono-nerd && omarchy-font-set 'BitstromWera Nerd Font'" },
                                    { icon: "󰛖", label: "Iosevka",        terminal: "omarchy-pkg-add ttf-iosevka-nerd && omarchy-font-set 'Iosevka Nerd Font Mono'" },
                                ]
                            },
                        ]
                    },
                    {
                        icon: "󰵮", label: "Development",
                        children: [
                            { icon: "󰫏", label: "Ruby on Rails", terminal: "omarchy-install-dev-env ruby" },
                            { icon: "󰛦", label: "Node.js",       terminal: "omarchy-install-dev-env node" },
                            { icon: "",  label: "Bun",            terminal: "omarchy-install-dev-env bun" },
                            { icon: "",  label: "Deno",           terminal: "omarchy-install-dev-env deno" },
                            { icon: "󰟓",  label: "Go",             terminal: "omarchy-install-dev-env go" },
                            { icon: "",  label: "PHP",            terminal: "omarchy-install-dev-env php" },
                            { icon: "",  label: "Laravel",        terminal: "omarchy-install-dev-env laravel" },
                            { icon: "",  label: "Symfony",        terminal: "omarchy-install-dev-env symfony" },
                            { icon: "",  label: "Python",         terminal: "omarchy-install-dev-env python" },
                            { icon: "",  label: "Elixir",         terminal: "omarchy-install-dev-env elixir" },
                            { icon: "",  label: "Phoenix",        terminal: "omarchy-install-dev-env phoenix" },
                            { icon: "",  label: "Zig",            terminal: "omarchy-install-dev-env zig" },
                            { icon: "",  label: "Rust",           terminal: "omarchy-install-dev-env rust" },
                            { icon: "",  label: "Java",           terminal: "omarchy-install-dev-env java" },
                            { icon: "󰪮",  label: ".NET",           terminal: "omarchy-install-dev-env dotnet" },
                            { icon: "",  label: "OCaml",          terminal: "omarchy-install-dev-env ocaml" },
                            { icon: "",  label: "Clojure",        terminal: "omarchy-install-dev-env clojure" },
                            { icon: "",  label: "Scala",          terminal: "omarchy-install-dev-env scala" },
                            { icon: "󰡨", label: "Docker DBs",     terminal: "omarchy-install-docker-dbs" },
                        ]
                    },
                    {
                        icon: "", label: "Editor",
                        children: [
                            { icon: "", label: "VSCode",       terminal: "omarchy-install-vscode" },
                            { icon: "", label: "Cursor",       terminal: "omarchy-pkg-aur-add cursor-bin" },
                            { icon: "", label: "Zed",          terminal: "omarchy-pkg-add zed" },
                            { icon: "", label: "Sublime Text", terminal: "omarchy-pkg-aur-add sublime-text-4" },
                            { icon: "", label: "Helix",        terminal: "omarchy-pkg-add helix" },
                            { icon: "", label: "Emacs",        terminal: "omarchy-pkg-add emacs-wayland" },
                        ]
                    },
                    {
                        icon: "", label: "Terminal",
                        children: [
                            { icon: "", label: "Alacritty", terminal: "omarchy-install-terminal alacritty" },
                            { icon: "", label: "Ghostty",   terminal: "omarchy-install-terminal ghostty" },
                            { icon: "", label: "Kitty",     terminal: "omarchy-install-terminal kitty" },
                        ]
                    },
                    {
                        icon: "󱚤", label: "AI",
                        children: [
                            { icon: "",  label: "Dictation",   terminal: "omarchy-voxtype-install" },
                            { icon: "󱚤", label: "Claude Code", terminal: "omarchy-pkg-add claude-code" },
                            { icon: "󱚤", label: "Codex",       terminal: "omarchy-pkg-add openai-codex" },
                            { icon: "󱚤", label: "Gemini CLI",  terminal: "omarchy-pkg-add gemini-cli" },
                            { icon: "󱚤", label: "Copilot CLI", terminal: "omarchy-pkg-add github-copilot-cli" },
                            { icon: "󱚤", label: "Cursor CLI",  terminal: "omarchy-pkg-add cursor-cli" },
                            { icon: "󱚤", label: "LM Studio",   terminal: "omarchy-pkg-aur-add lmstudio-bin" },
                            { icon: "󱚤", label: "Ollama",       terminal: "omarchy-pkg-add ollama" },
                            { icon: "󱚤", label: "Crush",        terminal: "omarchy-pkg-aur-add crush-bin" },
                        ]
                    },
                    { icon: "󰍲", label: "Windows VM", terminal: "omarchy-windows-vm install" },
                    {
                        icon: "", label: "Gaming",
                        children: [
                            { icon: "",  label: "Steam",           terminal: "omarchy-install-steam" },
                            { icon: "󰢹", label: "NVIDIA GeForce",  terminal: "omarchy-install-geforce-now" },
                            { icon: "",  label: "RetroArch",       terminal: "omarchy-pkg-aur-add retroarch retroarch-assets libretro libretro-fbneo" },
                            { icon: "󰍳", label: "Minecraft",       terminal: "omarchy-pkg-add minecraft-launcher" },
                            { icon: "󰖺", label: "Xbox Controller", terminal: "omarchy-install-xbox-controllers" },
                        ]
                    },
                ]
            },
            {
                icon: "󰒓", label: "Settings", action: "openSettings"
            },
            {
                icon: "󰭌", label: "Remove",
                children: [
                    { icon: "󰣇", label: "Package",    cmd: "xdg-terminal-exec --app-id=org.omarchy.terminal omarchy-pkg-remove" },
                    { icon: "󰖟",  label: "Web App",     terminal: "omarchy-webapp-remove" },
                    { icon: "󰆧",  label: "TUI",         terminal: "omarchy-tui-remove" },
                    { icon: "",  label: "Dictation",   terminal: "omarchy-voxtype-remove" },
                    { icon: "󰸌", label: "Theme",       terminal: "omarchy-theme-remove" },
                    { icon: "󰍲", label: "Windows VM",  terminal: "omarchy-windows-vm remove" },
                    { icon: "󰈷", label: "Fingerprint", terminal: "omarchy-setup-fingerprint --remove" },
                    { icon: "󰯄",  label: "Fido2",        terminal: "omarchy-setup-fido2 --remove" },
                    { icon: "󰏓", label: "Preinstalls", terminal: "omarchy-remove-preinstalls" },
                    {
                        icon: "󰵮", label: "Development",
                        children: [
                            { icon: "󰫏", label: "Ruby on Rails", terminal: "omarchy-remove-dev-env ruby" },
                            { icon: "󰛦", label: "Node.js",       terminal: "omarchy-remove-dev-env node" },
                            { icon: "",  label: "Bun",            terminal: "omarchy-remove-dev-env bun" },
                            { icon: "",  label: "Deno",           terminal: "omarchy-remove-dev-env deno" },
                            { icon: "󰟓",  label: "Go",             terminal: "omarchy-remove-dev-env go" },
                            { icon: "",  label: "PHP",            terminal: "omarchy-remove-dev-env php" },
                            { icon: "",  label: "Laravel",        terminal: "omarchy-remove-dev-env laravel" },
                            { icon: "",  label: "Symfony",        terminal: "omarchy-remove-dev-env symfony" },
                            { icon: "",  label: "Python",         terminal: "omarchy-remove-dev-env python" },
                            { icon: "",  label: "Elixir",         terminal: "omarchy-remove-dev-env elixir" },
                            { icon: "",  label: "Phoenix",        terminal: "omarchy-remove-dev-env phoenix" },
                            { icon: "",  label: "Zig",            terminal: "omarchy-remove-dev-env zig" },
                            { icon: "",  label: "Rust",           terminal: "omarchy-remove-dev-env rust" },
                            { icon: "",  label: "Java",           terminal: "omarchy-remove-dev-env java" },
                            { icon: "󰪮",  label: ".NET",           terminal: "omarchy-remove-dev-env dotnet" },
                            { icon: "",  label: "OCaml",          terminal: "omarchy-remove-dev-env ocaml" },
                            { icon: "",  label: "Clojure",        terminal: "omarchy-remove-dev-env clojure" },
                            { icon: "",  label: "Scala",          terminal: "omarchy-remove-dev-env scala" },
                        ]
                    },
                ]
            },
            {
                icon: "󰅢", label: "Update",
                children: [
                    { icon: "<span font='omarchy'>\ue900</span>",  label: "Omarchy",      terminal: "omarchy-update" },
                    {
                        icon: "󰔫", label: "Channel",
                        children: [
                            { icon: "🟢", label: "Stable", terminal: "omarchy-channel-set stable" },
                            { icon: "🟡", label: "RC",     terminal: "omarchy-channel-set rc" },
                            { icon: "🟠", label: "Edge",   terminal: "omarchy-channel-set edge" },
                            { icon: "🔴", label: "Dev",    terminal: "omarchy-channel-set dev" },
                        ]
                    },
                    {
                        icon: "", label: "Config",
                        children: [
                            { icon: "", label: "Hyprland",   terminal: "omarchy-refresh-hyprland" },
                            { icon: "", label: "Hypridle",   terminal: "omarchy-refresh-hypridle" },
                            { icon: "", label: "Hyprlock",   terminal: "omarchy-refresh-hyprlock" },
                            { icon: "", label: "Hyprsunset", terminal: "omarchy-refresh-hyprsunset" },
                            { icon: "󱣴", label: "Plymouth",   terminal: "omarchy-refresh-plymouth" },
                            { icon: "", label: "Swayosd",    terminal: "omarchy-refresh-swayosd" },
                            { icon: "", label: "Tmux",       terminal: "omarchy-refresh-tmux" },
                            { icon: "󰍜", label: "Walker",     terminal: "omarchy-refresh-walker" },
                            { icon: "󱔓", label: "Waybar",     terminal: "omarchy-refresh-waybar" },
                        ]
                    },
                    { icon: "󰸌", label: "Extra Themes", terminal: "omarchy-theme-update" },
                    {
                        icon: "󰒋", label: "Process",
                        children: [
                            { icon: "", label: "Hypridle",   cmd: "omarchy-restart-hypridle" },
                            { icon: "", label: "Hyprsunset", cmd: "omarchy-restart-hyprsunset" },
                            { icon: "", label: "Swayosd",    cmd: "omarchy-restart-swayosd" },
                            { icon: "󰍜", label: "Walker",     cmd: "omarchy-restart-walker" },
                            { icon: "󱔓", label: "Waybar",     cmd: "omarchy-restart-waybar" },
                        ]
                    },
                    {
                        icon: "󰇅", label: "Hardware",
                        children: [
                            { icon: "", label: "Audio",     terminal: "omarchy-restart-pipewire" },
                            { icon: "", label: "Wi-Fi",     terminal: "omarchy-restart-wifi" },
                            { icon: "󰂯", label: "Bluetooth", terminal: "omarchy-restart-bluetooth" },
                        ]
                    },
                    { icon: "",  label: "Firmware",  terminal: "omarchy-update-firmware" },
                    {
                        icon: "", label: "Password",
                        children: [
                            { icon: "", label: "Drive Encryption", terminal: "omarchy-drive-set-password" },
                            { icon: "", label: "User",             terminal: "passwd" },
                        ]
                    },
                    { icon: "󰇧", label: "Timezone", terminal: "omarchy-tz-select" },
                    { icon: "󱑆", label: "Time",      terminal: "omarchy-update-time" },
                ]
            },
            {
                icon: "", label: "About",
                action: "about"
            },
            {
                icon: "⏼", label: "System",
                children: [
                    { icon: "󱄄", label: "Screensaver", cmd: "omarchy-launch-screensaver force" },
                    { icon: "",  label: "Lock",         cmd: "hyprlock" },
                    { icon: "󰒲", label: "Suspend",      cmd: "systemctl suspend" },
                    { icon: "󰤁", label: "Hibernate",    cmd: "systemctl hibernate" },
                    { icon: "󰍃", label: "Logout",       cmd: "omarchy-system-logout" },
                    { icon: "󰜉", label: "Restart",      cmd: "omarchy-system-reboot" },
                    { icon: "󰐥", label: "Shutdown",     cmd: "omarchy-system-shutdown" },
                ]
            },
        ]
    }
}
