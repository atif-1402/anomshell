import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    property bool panelOpen: false
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
        }
    }

    function dismiss(notif) {
        notif.dismiss()
        root.notifications = root.notifications.filter(n => n.id !== notif.id)
        root.hiddenToasts = root.hiddenToasts.filter(id => id !== notif.id)
    }

    function hideToast(id) {
        root.hiddenToasts = [...root.hiddenToasts, id]
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

    function isCritical(notif) {
        return notif.urgency === NotificationUrgency.Critical
    }
}