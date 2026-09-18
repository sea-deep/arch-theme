pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as QSNotifications
import "../theme"

Singleton {
    id: root

    readonly property alias notificationList: server.trackedNotifications
    property var latestNotification: null
    property var activeToasts: []
    property int unreadCount: 0
    readonly property bool dndEnabled: UiState.dndEnabled

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
        if (!notification || dndEnabled) return
        var current = (activeToasts || []).slice()
        current = current.filter(n => !areSameNotification(n, notification))
        current.unshift(notification)
        if (current.length > 4)
            current = current.slice(0, 4)
        activeToasts = current
    }

    function removeToast(notification) {
        // Closed QObjects can become null before a toast's exit animation ends.
        // Always prune those entries, including when the timer passes null.
        activeToasts = (activeToasts || []).filter(n => n && !areSameNotification(n, notification))
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
        if (notification)
            notification.dismiss()
    }

    function handleNotificationClosed(notification) {
        // Clients and action invocations can close notifications too. Release
        // every UI reference while the QObject is still valid in closed().
        removeToast(notification)
        unreadCount = Math.max(0, unreadCount - 1)
        if (latestNotification === notification)
            latestNotification = null
    }

    function markRead() {
        unreadCount = 0
    }

    function toggleDnd() {
        UiState.dndEnabled = !UiState.dndEnabled
        if (UiState.dndEnabled) {
            activeToasts = []
            UiState.notificationPreviewVisible = false
        }
    }

    QSNotifications.NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: (notification) => {
            notification.closed.connect(() => root.handleNotificationClosed(notification))
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
