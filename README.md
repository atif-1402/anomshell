# Omashell - Alpha Version
Omashell is a Quickshell configuration inspired by Omarchy OS. It includes a bar, launcher, OSD, settings, and media widgets built while experimenting with Quickshell and customization. The goal is to keep things simple, fast, and easy to tweak.

---

## Showcase - (There is more)

https://github.com/user-attachments/assets/c5494543-a2bb-4d9e-87ff-f3982a5a8182

<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/08277fd8-b5a9-48ee-81a6-a9a0fba17c70" />
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/bb68d506-e270-4c1d-bbae-ecaa86840381" />
<img width="1366" height="768" alt="omashell-2026-03-27-233841" src="https://github.com/user-attachments/assets/08e5a8e9-9c87-4439-933e-56fcde67c805" />

---

## Features and Usability

### 1) Bar
A minimal bar with clean workspace styling, omarchy status modules, and performance stats. It’s theme‑aware, lightweight, and designed to stay out of the way while still being informative.

Usage -
- Omarchy button: opens the main launcher.
- Workspaces: shows your workspace list and highlights the active one.
- Media: displays the current track and opens the mini player card on hover (Take colors from the Album Cover Art to make it more Aesthetic).
- System stats: quick glance CPU and RAM which shows progress bar on hover.
- Tray: Only for Applications.
- Notification and Control Center Panels: Panel where you can access the notifications and volume sliders, DND, wifi and bt manager.
- Clock: shows the time and date. On hover it shows calendar.
- Notifications indicator: lets you know if something arrived.
- In Settings you can switch bar position, bar style, Launcher logo and Workspace Style from the settings.
- Also contains the module like Omarchy idle locking, etc

### 2) Launcher
A fast, minimal launcher for apps, search, and quick actions. It opens instantly, filters as you type, and stays clean and distraction‑free.

Usage - 
- Instant search for system actions (Global Search through whole sub menus).
- A Quickshell launcher inspired by the Omarchy Walker menu.
- Quick sections for utilities and custom menus (Dedicated keybinds for them too).
- Keyboard‑first: type, hit Enter, done.

### 3) Theme and Background Picker
A new theme and background picker interface.

Usage - 
- Dedicated Keybinds for both.
- A one row scrollable layout for both.
- Keyboard and Mouse Navigations.

### 4) OSD
A new style OSD for volume and media with a fluid like visualizer running in its background

Usage - 
- Dedicated Keybinds for each OSD.
- Media OSD shows the progress bar and cover art.

### 5) Media Card 
A media card that shows on hovering on the Media Module of bar and it is Inspired by end4-dots 

Usage - 
- Hover on the Media module of bar to access it.
- Functional Play/Pause and Forward Track/Backward Track buttons.
- Adapt color of Album Cover Art.

### 6) Clipboard and Keybinds Manager
A clean Manager with organized Clipboard and keybinds 

Usage -
- Both have there Dedicated Keybinds.
- Image previews in Clipboard with a clear all button 

### 7) Settings 
A clean control panel to manage bar style/position, OSD placement, launcher icon, workspace style, and general behavior without touching files. Everything updates live and stays aligned with your theme.

Usage - 
- Bar: choose between layouts and positions that fit your screen and workflow.
- OSD: move the volume/brightness overlay anywhere you like.
- Launcher: swap the logo/icon to match your personal theme or setup..
- Workspaces: switch visual styles and adjust numbering display.
- General: control behavior that affects the whole shell, all in one UI.
- Changes apply live so you can tweak and preview instantly.

---

## Omashell Keybindings

### Main Controls

| Keybind                          | Action                  |
| -------------------------------- | ----------------------- |
| **SUPER + SHIFT + Q**            | Start Quickshell        |
| **SUPER + ALT + SPACE**          | Open menu launcher      |
| **SUPER + SPACE**                | Open app launcher       |
| **SUPER + CTRL + SHIFT + SPACE** | Open theme picker       |
| **SUPER + CTRL + ALT + SPACE**   | Open settings           |
| **SUPER + K**                    | Open keybindings viewer |
| **SUPER + ESC**                  | Open system menu        |
| **SUPER + CTRL + V**             | Open clipboard manager  |
| **SUPER + CTRL + SPACE**         | Open background picker  |
| **SUPER + CTRL + ,**             | Toggle Do Not Disturb   |

### Media Controls

| Keybind             | Action          |
| ------------------- | --------------- |
| **Volume Up Key**   | Increase volume |
| **Volume Down Key** | Decrease volume |
| **Mute Key**        | Toggle mute     |

### Brightness Controls

| Keybind                 | Action              |
| ----------------------- | ------------------- |
| **Brightness Up Key**   | Increase brightness |
| **Brightness Down Key** | Decrease brightness |

### Screen Tools

| Keybind         | Action               |
| --------------- | -------------------- |
| **ALT + PRINT** | Open screen recorder |

## Repo Structure

```
omashell/
├── config/
│   ├── hypr/
│   │   └── bindings.conf
│   └── quickshell/
│
├── local/
│   └── bin/
│       ├── qs.sh
│       └── wb-kill.sh
│
├── LICENSE
└── README.md
```
## Installation

> ⚠️ **Warning**
> This setup modifies your Hyprland configuration. **Backup your configs before continuing.**
> Do **not** blindly overwrite configs unless you know what you are doing.

### Dependencies

Install required packages:

```bash
sudo pacman -S --needed quickshell cava cliphist wl-clipboard imagemagick jq
```

### Clone repository

```bash
git clone https://github.com/atif-1402/omashell.git
cd omashell
```

### Backup existing configuration (Recommended)

```bash
cp -r ~/.config/quickshell ~/.config/quickshell.backup 2>/dev/null
cp ~/.config/hypr/bindings.conf ~/.config/hypr/bindings.conf.backup 2>/dev/null
```

### Install Quickshell config

Copy the quickshell configuration:

```bash
cp -r config/quickshell ~/.config/
```

### Install Omashell keybinds (Manual merge recommended)

Open:

```
config/hypr/bindings.conf
```

Copy the Quickshell binds and **manually paste them at the end of your:**

```
~/.config/hypr/bindings.conf
```

This avoids breaking existing keybind setups.

### Install helper scripts

```bash
cp local/bin/* ~/.local/bin/
chmod +x ~/.local/bin/qs.sh
chmod +x ~/.local/bin/wb-kill.sh
```

### Start Quickshell

Run:

```bash
~/.local/bin/qs.sh
```

or use the provided keybind:

```
SUPER + SHIFT + Q
```

### Notes

* Ensure `~/.local/bin` is in your `$PATH`
* Restart Hyprland if binds don't work
* Manual config merging is intentional to prevent overwriting user setups
* Tested on a personal Omarchy setup.

### Troubleshooting

Verify quickshell runs:

```bash
quickshell
```

Check IPC:

```bash
quickshell ipc list
```

Verify scripts:

```bash
ls -l ~/.local/bin
```

## Status (Alpha)
Omashell is in active development. Expect occasional bugs or rough edges. Please report issues with logs and screenshots so we can fix them fast.

## Credits
Thanks to [@oldjobobo](https://github.com/OldJobobo) for helping.
