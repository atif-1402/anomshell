import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service

    property bool active: false
    property var entries: []
    property var filtered: []
    property string query: ""
    property int selectedIdx: 0
    property bool loading: false
    property string backendError: ""

    property string previewSource: ""
    property string previewMime: ""
    property bool hasImagePreview: false
    property bool depsReady: false
    property bool watcherReady: false
    property string previewFilePath: ""

    signal copied()

    onQueryChanged: applyFilter()

    function shellQuote(s) {
        if (s === undefined || s === null)
            return "''"
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function refresh() {
        if (!depsReady) {
            ensureDepsAndRefresh()
            return
        }

        loading = true
        backendError = ""
        listProc.stdout.buf = ""
        listProc.command = ["bash", "-lc",
            "command -v cliphist >/dev/null 2>&1 || exit 127; " +
            "out=$(cliphist list 2>&1); ec=$?; " +
            "if [ $ec -ne 0 ]; then " +
            "if printf '%s' \"$out\" | grep -qi 'please store something first'; then exit 0; fi; " +
            "printf '%s\\n' \"$out\"; exit $ec; fi; " +
            "printf '%s\\n' \"$out\""
        ]
        listProc.running = false
        listProc.running = true
    }

    function ensureDepsAndRefresh() {
        backendError = ""
        depCheckProc.stdout.buf = ""
        depCheckProc.running = false
        depCheckProc.running = true
    }

    function applyFilter() {
        const q = query.trim().toLowerCase()
        if (q === "") {
            filtered = entries.slice(0)
        } else {
            filtered = entries.filter(function(e) {
                return (e.preview || "").toLowerCase().indexOf(q) !== -1
                    || (e.id || "").toLowerCase().indexOf(q) !== -1
            })
        }

        if (filtered.length === 0) {
            selectedIdx = 0
            clearPreview()
            return
        }

        selectedIdx = Math.max(0, Math.min(selectedIdx, filtered.length - 1))
        updatePreviewForSelected()
    }

    function clearPreview() {
        hasImagePreview = false
        previewSource = ""
        previewMime = ""
        cleanupPreviewFile()
    }

    function cleanupPreviewFile() {
        if (!previewFilePath || previewFilePath === "")
            return
        cleanupProc.command = ["bash", "-lc", "rm -f " + shellQuote(previewFilePath)]
        cleanupProc.running = false
        cleanupProc.running = true
        previewFilePath = ""
    }

    function select(index) {
        if (filtered.length === 0) return
        selectedIdx = Math.max(0, Math.min(index, filtered.length - 1))
        updatePreviewForSelected()
    }

    function moveUp() {
        if (filtered.length === 0) return
        selectedIdx = Math.max(0, selectedIdx - 1)
        updatePreviewForSelected()
    }

    function moveDown() {
        if (filtered.length === 0) return
        selectedIdx = Math.min(filtered.length - 1, selectedIdx + 1)
        updatePreviewForSelected()
    }

    function copySelected() {
        if (filtered.length === 0) return
        copyEntry(filtered[selectedIdx])
    }

    function copyEntry(entry) {
        if (!entry || !entry.raw) return
        const line = shellQuote(entry.raw)
        const cmd = "line=" + line + "; printf '%s\\n' \"$line\" | cliphist decode | wl-copy"
        copyProc.command = ["bash", "-lc", cmd]
        copyProc.running = false
        copyProc.running = true
    }

    function deleteEntry(entry) {
        if (!entry || !entry.raw) return
        const line = shellQuote(entry.raw)
        const cmd = "line=" + line + "; printf '%s\\n' \"$line\" | cliphist delete"
        deleteProc.command = ["bash", "-lc", cmd]
        deleteProc.running = false
        deleteProc.running = true
    }

    function deleteSelected() {
        if (filtered.length === 0) return
        deleteEntry(filtered[selectedIdx])
    }

    function clearAll() {
        wipeProc.command = ["bash", "-lc", "cliphist wipe"]
        wipeProc.running = false
        wipeProc.running = true
    }

    function updatePreviewForSelected() {
        if (filtered.length === 0) {
            clearPreview()
            return
        }

        const entry = filtered[selectedIdx]
        if (!entry || !entry.raw) {
            clearPreview()
            return
        }

        cleanupPreviewFile()
        previewProc.stdout.buf = ""
        const line = shellQuote(entry.raw)
        const cmd = "line=" + line + "; "
            + "tmp=$(mktemp /tmp/qs-clip-prev.XXXXXX.bin) || exit 1; "
            + "if printf '%s\\n' \"$line\" | cliphist decode > \"$tmp\" 2>/dev/null; then "
            + "mime=$(file --mime-type -b \"$tmp\" 2>/dev/null || true); "
            + "if [[ \"$mime\" == image/* ]]; then "
            + "printf '__IMG__\\n%s\\n%s\\n' \"$mime\" \"$tmp\"; "
            + "else rm -f \"$tmp\"; printf '__NOIMG__'; fi; "
            + "else rm -f \"$tmp\"; printf '__NOIMG__'; fi"

        previewProc.command = ["bash", "-lc", cmd]
        previewProc.running = false
        previewProc.running = true
    }

    Process {
        id: listProc
        command: ["bash", "-lc",
            "out=$(cliphist list 2>&1); ec=$?; " +
            "if [ $ec -ne 0 ]; then " +
            "if printf '%s' \"$out\" | grep -qi 'please store something first'; then exit 0; fi; " +
            "printf '%s\\n' \"$out\"; exit $ec; fi; " +
            "printf '%s\\n' \"$out\""
        ]
        running: false

        stdout: SplitParser {
            property string buf: ""
            onRead: data => {
                buf += data + "\n"
            }
        }

        onExited: exitCode => {
            service.loading = false

            if (exitCode !== 0) {
                service.entries = []
                service.filtered = []
                const err = (listProc.stdout.buf || "").trim()
                service.backendError = err !== ""
                    ? ("Clipboard backend error:\n" + err)
                    : "cliphist is not available. Install and start cliphist daemon."
                service.clearPreview()
                return
            }

            const out = listProc.stdout.buf || ""
            const lines = out.split("\n")
            const parsed = []

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim()
                if (!line) continue

                const tab = line.indexOf("\t")
                if (tab === -1) {
                    parsed.push({
                        raw: line,
                        id: "",
                        preview: line,
                        isBinaryHint: line.indexOf("[[ binary data") !== -1
                    })
                } else {
                    const id = line.slice(0, tab).trim()
                    const preview = line.slice(tab + 1).trim()
                    parsed.push({
                        raw: line,
                        id: id,
                        preview: preview,
                        isBinaryHint: preview.indexOf("[[ binary data") !== -1
                    })
                }
            }

            service.entries = parsed
            service.applyFilter()
            listProc.stdout.buf = ""
        }
    }

    Process {
        id: depCheckProc
        command: ["bash", "-lc",
            "missing=''; " +
            "for c in cliphist wl-copy file base64; do " +
            "command -v \"$c\" >/dev/null 2>&1 || missing=\"$missing $c\"; " +
            "done; " +
            "missing=${missing# }; " +
            "if [ -z \"$missing\" ]; then echo __OK__; exit 0; fi; " +
            "echo \"$missing\"; exit 1"
        ]
        running: false

        stdout: SplitParser {
            property string buf: ""
            onRead: data => {
                buf += data + "\n"
            }
        }

        onExited: exitCode => {
            const out = (depCheckProc.stdout.buf || "").trim()
            depCheckProc.stdout.buf = ""

            if (exitCode === 0 && out.indexOf("__OK__") !== -1) {
                depsReady = true
                if (!watcherReady) {
                    watcherReady = true
                    seedProc.running = false
                    seedProc.running = true
                } else {
                    refresh()
                }
                return
            }

            depsReady = false
            backendError =
                "Missing deps: " + out + "\nInstall: sudo pacman -S --needed cliphist wl-clipboard file coreutils"
            loading = false
            clearPreview()
        }
    }

    Process {
        id: seedProc
        command: ["bash", "-lc", "wl-paste -n 2>/dev/null | cliphist store >/dev/null 2>&1 || true"]
        running: false
        onExited: {
            refresh()
        }
    }

    Process {
        id: watcherProc
        command: ["bash", "-lc", "wl-paste --watch cliphist store"]
        running: depsReady && watcherReady
    }

    Process {
        id: copyProc
        command: ["bash", "-lc", "true"]
        running: false
        onExited: {
            service.copied()
        }
    }

    Process {
        id: cleanupProc
        command: ["bash", "-lc", "true"]
        running: false
    }

    Process {
        id: deleteProc
        command: ["bash", "-lc", "true"]
        running: false
        onExited: {
            service.refresh()
        }
    }

    Process {
        id: wipeProc
        command: ["bash", "-lc", "true"]
        running: false
        onExited: {
            service.refresh()
        }
    }

    Process {
        id: previewProc
        command: ["bash", "-lc", "true"]
        running: false

        stdout: SplitParser {
            property string buf: ""
            onRead: data => {
                buf += data + "\n"
            }
        }

        onExited: {
            const raw = previewProc.stdout.buf || ""
            previewProc.stdout.buf = ""

            if (!raw.startsWith("__IMG__")) {
                service.clearPreview()
                return
            }

            const parts = raw.split("\n")
            if (parts.length < 3) {
                service.clearPreview()
                return
            }

            const mime = parts[1].trim()
            const path = parts[2].trim()
            if (!mime || !path) {
                service.clearPreview()
                return
            }

            service.previewMime = mime
            service.previewFilePath = path
            service.previewSource = "file://" + path
            service.hasImagePreview = true
        }
    }

    onActiveChanged: {
        if (active)
            ensureDepsAndRefresh()
    }
}
