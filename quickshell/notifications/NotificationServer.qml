pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as QSNotifications

Singleton {
    id: root

    readonly property alias notificationList: server.trackedNotifications
    property var latestNotification: null
    property int unreadCount: 0
    property bool dndEnabled: false

    signal notificationReceived(var notification)

    function clearAll() {
        const notifications = server.trackedNotifications.values.slice()
        for (let i = 0; i < notifications.length; ++i)
            notifications[i].dismiss()

        unreadCount = 0
        latestNotification = null
    }

    function dismiss(notification) {
        if (notification)
            notification.dismiss()

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

    Process {
        id: soundProcess
        command: ["bash", "-c", "paplay /usr/share/sounds/freedesktop/stereo/message.oga &"]
        running: false
    }

    QSNotifications.NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: (notification) => {
            notification.tracked = true
            root.latestNotification = notification

            if (!notification.lastGeneration)
                root.unreadCount++

            if (!root.dndEnabled && !notification.lastGeneration) {
                soundProcess.running = false
                soundProcess.running = true
                root.notificationReceived(notification)
            }
        }
    }
}
