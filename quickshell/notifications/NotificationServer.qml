pragma Singleton
import QtQuick 2.15
import Quickshell 1.0
import Quickshell.Io 1.0
import Quickshell.Services.Notifications 1.0

Item {
    id: root

    property ListModel notificationList: ListModel {}
    property int unreadCount: 0
    property bool dndEnabled: false

    function clearAll() {
        notificationList.clear();
        unreadCount = 0;
    }

    function dismiss(index) {
        if (index >= 0 && index < notificationList.count) {
            notificationList.remove(index);
            unreadCount = Math.max(0, unreadCount - 1);
        }
    }

    function toggleDnd() {
        dndEnabled = !dndEnabled;
    }

    NotificationServer {
        id: server
        onNotification: (notification) => {
            if (root.dndEnabled) return;
            notification.tracked = true;
            
            root.notificationList.insert(0, {
                "nId": notification.id,
                "appName": notification.appName,
                "appIcon": notification.appIcon,
                "summary": notification.summary,
                "body": notification.body,
                "urgency": notification.urgency,
                "timestamp": new Date().toLocaleTimeString()
            });
            root.unreadCount++;

            playProcess.running = true;
            
            if (notification.urgency !== NotificationUrgency.Critical) {
                var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 5000; running: true; onTriggered: { root.dismiss(0); this.destroy(); } }', root);
            }
        }
    }

    Process {
        id: playProcess
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"]
    }
}
