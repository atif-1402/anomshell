import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    property bool panelOpen: false
    property bool dndEnabled: false
    property var notifications: []
    property var hiddenToasts: []

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true
            root.notifications = [notif, ...root.notifications]
            if (root.dndEnabled && !root.isCritical(notif))
                root.hideToast(notif.id)
        }
    }

    function dismiss(notif) {
        notif.dismiss()
        root.notifications = root.notifications.filter(n => n.id !== notif.id)
        root.hiddenToasts = root.hiddenToasts.filter(id => id !== notif.id)
    }

    function hideToast(id) {
        if (!root.hiddenToasts.includes(id))
            root.hiddenToasts = [...root.hiddenToasts, id]
    }

    function hideToasts(ids) {
        const next = [...root.hiddenToasts]
        for (const id of ids || []) {
            if (!next.includes(id))
                next.push(id)
        }
        root.hiddenToasts = next
    }

    function clearAll() {
        const copy = [...root.notifications]
        copy.forEach(n => n.dismiss())
        root.notifications = []
        root.hiddenToasts = []
    }

    function togglePanel() {
        panelOpen = !panelOpen
    }

    function setDnd(enabled) {
        dndEnabled = enabled
        if (!enabled) return

        for (const notif of root.notifications) {
            if (!root.isCritical(notif))
                root.hideToast(notif.id)
        }
    }

    function toggleDnd() {
        setDnd(!dndEnabled)
    }

    function appNameFor(notif) {
        return (notif?.appName || "Unknown").trim() || "Unknown"
    }

    function appNames() {
        const seen = {}
        const out = []
        for (const notif of root.notifications) {
            const name = appNameFor(notif)
            if (seen[name]) continue
            seen[name] = true
            out.push(name)
        }
        return out
    }

    function notificationsForApp(appName) {
        if (!appName) return [...root.notifications]
        return root.notifications.filter(n => appNameFor(n) === appName)
    }

    function groupedNotifications(appName) {
        const groups = {}
        const order = []
        for (const notif of notificationsForApp(appName)) {
            const name = appNameFor(notif)
            if (!groups[name]) {
                groups[name] = {
                    key: name,
                    appName: name,
                    latest: notif,
                    count: 0,
                    items: []
                }
                order.push(name)
            }
            groups[name].count += 1
            groups[name].items.push(notif)
        }
        return order.map(name => groups[name])
    }

    function dismissMany(items) {
        for (const notif of items || [])
            dismiss(notif)
    }

    function isCritical(notif) {
        return notif.urgency === NotificationUrgency.Critical
    }
}
