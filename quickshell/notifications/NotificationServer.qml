pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as QSNotifications

Singleton {
    id: root

    readonly property alias notificationList: server.trackedNotifications
    property var latestNotification: null
    property var activeToasts: []
    property int unreadCount: 0
    property bool dndEnabled: false

    signal notificationReceived(var notification)

    function areSameNotification(a, b) {
        if (!a || !b) return false
        if (a === b) return true
        if (a.id !== undefined && a.id !== null && b.id !== undefined && b.id !== null) {
            return a.id === b.id
        }
        if (a.summary === b.summary && a.body === b.body && a.appName === b.appName) {
            return true
        }
        return false
    }

    function addToast(notification) {
        if (!notification) return
        var current = (activeToasts || []).slice()
        current = current.filter(n => !areSameNotification(n, notification))
        current.unshift(notification)
        if (current.length > 8)
            current = current.slice(0, 8)
        activeToasts = current
    }

    function removeToast(notification) {
        if (!notification) return
        activeToasts = (activeToasts || []).filter(n => !areSameNotification(n, notification))
        if (activeToasts.length === 0) {
            UiState.notificationPreviewVisible = false
        }
    }

    function clearAll() {
        const notifications = server.trackedNotifications.values.slice()
        for (let i = 0; i < notifications.length; ++i)
            notifications[i].dismiss()

        unreadCount = 0
        latestNotification = null
        activeToasts = []
        UiState.notificationPreviewVisible = false
    }

    function dismiss(notification) {
        if (notification) {
            notification.dismiss()
            removeToast(notification)
        }

        unreadCount = Math.max(0, unreadCount - 1)
        if (latestNotification === notification)
            latestNotification = null
    }

    function markRead() {
        unreadCount = 0
    }

    function toggleDnd() {
        dndEnabled = !dndEnabled
    }

    QSNotifications.NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: (notification) => {
            notification.tracked = true
            root.latestNotification = notification

            if (!notification.lastGeneration) {
                root.unreadCount++
                if (!root.dndEnabled) {
                    root.addToast(notification)
                    Quickshell.execDetached(["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"])
                    root.notificationReceived(notification)
                }
            }
        }
    }
}
