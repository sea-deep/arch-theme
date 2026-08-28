pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    property ListModel notificationList: ListModel {}
    property var latestNotification: null
    property int unreadCount: 0
    property bool dndEnabled: false

    signal notificationReceived()

    function clearAll() {
        notificationList.clear();
        unreadCount = 0;
        latestNotification = null;
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
            
            let item = {
                "nId": notification.id,
                "appName": notification.appName,
                "appIcon": notification.appIcon,
                "summary": notification.summary,
                "body": notification.body,
                "urgency": notification.urgency,
                "timestamp": new Date().toLocaleTimeString()
            };
            
            root.latestNotification = item;
            root.notificationList.insert(0, item);
            root.unreadCount++;
            root.notificationReceived();

            playProcess.running = true;
            
            if (notification.urgency !== NotificationUrgency.Critical) {
                var timer = Qt.createQmlObject('import QtQuick; Timer { interval: 5000; running: true; onTriggered: { root.dismiss(0); this.destroy(); } }', root);
            }
        }
    }

    Process {
        id: playProcess
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/message.oga"]
    }
}
