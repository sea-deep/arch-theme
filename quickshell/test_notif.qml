import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications as QSNotifications

PanelWindow {
    WlrLayershell.namespace: "test"
    color: "transparent"
    width: 200; height: 200
    QSNotifications.NotificationServer {
        actionsSupported: true
        onNotification: (notification) => {
            console.log("PROPERTIES:", Object.keys(notification))
            console.log("ACTIONS:", JSON.stringify(notification.actions))
            Quickshell.exit(0)
        }
    }
    Component.onCompleted: {
        Quickshell.execute("notify-send", ["-A", "action1=Test", "Hello", "World"])
    }
}
