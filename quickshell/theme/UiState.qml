pragma Singleton
import Quickshell
import QtQml

Singleton {
    id: root

    PersistentProperties {
        id: persisted
        reloadableId: "ui-state"

        property bool caffeineEnabled: false
        property real comfortValue: 0
        property real grayscaleValue: 0
        property real vividValue: 0
    }

    property alias caffeineEnabled: persisted.caffeineEnabled
    property alias comfortValue: persisted.comfortValue
    property alias grayscaleValue: persisted.grayscaleValue
    property alias vividValue: persisted.vividValue

    property bool isShaderInitialized: false

    FileView {
        id: shaderStateFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/shaders.json"
        watchChanges: true
        printErrors: false
        onFileChanged: root.loadShaderState()
    }

    function loadShaderState() {
        var text = shaderStateFile.text()
        if (!text || text.trim() === "") return
        try {
            var data = JSON.parse(text)
            if (data.comfort !== undefined) root.comfortValue = Number(data.comfort)
            if (data.grayscale !== undefined) root.grayscaleValue = Number(data.grayscale)
            if (data.vivid !== undefined) root.vividValue = Number(data.vivid)
            root.isShaderInitialized = true
        } catch(e) {}
    }

    Timer {
        id: shaderUpdateTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (!root.isShaderInitialized) return
            Quickshell.execDetached(["bash", "-c", "$HOME/.config/quickshell/scripts/update_shader.sh set_all " + Math.round(comfortValue) + " " + Math.round(grayscaleValue) + " " + Math.round(vividValue)])
        }
    }

    onComfortValueChanged: if (isShaderInitialized) shaderUpdateTimer.restart()
    onGrayscaleValueChanged: if (isShaderInitialized) shaderUpdateTimer.restart()
    onVividValueChanged: if (isShaderInitialized) shaderUpdateTimer.restart()

    Component.onCompleted: {
        loadShaderState()
        root.isShaderInitialized = true
    }
    property bool selectorVisible: false
    property bool screenshotVisible: false
    property bool recorderMenuVisible: false
    property string selectorMode: "apps"
    property bool notificationCenterVisible: false
    property string notificationScreen: ""
    property bool notificationPreviewVisible: false
    property string notificationPreviewScreen: ""
    property bool powerMenuVisible: false
    property string powerScreen: ""
    property bool clockMenuVisible: false
    property string clockScreen: ""
    property string clockTab: "calendar"
    property bool recorderActive: false
    property bool settingsVisible: false
    property bool quickControlVisible: false
    property string quickControlMode: "audio"
    property string quickControlScreen: ""
    property bool trayMenuVisible: false
    property var trayMenuHandle: null
    property string trayMenuTitle: ""
    property string trayMenuIcon: ""
    property string trayMenuScreen: ""
    property int trayMenuRightOffset: 2
    property bool networkVisible: false
    property string networkScreen: ""
    property bool emojiVisible: false
    property bool launcherVisible: false
    property bool clipboardVisible: false
    property string clipboardScreen: ""

    function toggleLauncher() {
        const shouldOpen = !launcherVisible
        closeOverlays()
        launcherVisible = shouldOpen
    }

    function toggleSelector(mode) {
        if (mode === "apps") {
            toggleLauncher()
            return
        }
        if (selectorVisible && selectorMode === mode) {
            selectorVisible = false
            return
        }

        closeOverlays()
        selectorMode = mode
        selectorVisible = true
    }

    function toggleNotifications(screenName) {
        const targetScreen = screenName || ""
        const shouldOpen = !notificationCenterVisible
            || notificationScreen !== targetScreen
        closeOverlays()
        notificationScreen = targetScreen
        notificationCenterVisible = shouldOpen
    }

    function showNotificationPreview(screenName) {
        if (notificationCenterVisible)
            return

        if (!notificationPreviewVisible)
            notificationPreviewScreen = screenName || ""
        notificationPreviewVisible = true
    }

    function togglePower(screenName) {
        const targetScreen = screenName || ""
        const shouldOpen = !powerMenuVisible || powerScreen !== targetScreen
        closeOverlays()
        powerScreen = targetScreen
        powerMenuVisible = shouldOpen
    }

    function toggleClock(screenName) {
        const targetScreen = screenName || ""
        const shouldOpen = !clockMenuVisible || clockScreen !== targetScreen
        closeOverlays()
        clockScreen = targetScreen
        clockMenuVisible = shouldOpen
    }

    function showClockTab(tab, screenName) {
        closeOverlays()
        clockTab = tab === "time" ? "time" : "calendar"
        clockScreen = screenName || ""
        clockMenuVisible = true
    }

    function toggleSettings() {
        const shouldOpen = !settingsVisible
        closeOverlays()
        settingsVisible = shouldOpen
    }

    function toggleQuickControl(mode, screenName) {
        // Clicks provide a concrete screen. IPC calls deliberately target the
        // single active shell instance instead of inheriting a stale monitor.
        const targetScreen = screenName || ""

        if (quickControlVisible && quickControlMode === mode
                && quickControlScreen === targetScreen) {
            quickControlVisible = false
            return
        }

        closeOverlays()
        quickControlMode = mode
        quickControlScreen = targetScreen
        quickControlVisible = true
    }

    function toggleNetwork(screenName) {
        const targetScreen = screenName || ""
        const shouldOpen = !networkVisible || networkScreen !== targetScreen
        closeOverlays()
        networkScreen = targetScreen
        networkVisible = shouldOpen
    }

    function toggleClipboard(screenName) {
        const targetScreen = screenName || ""
        const shouldOpen = !clipboardVisible || clipboardScreen !== targetScreen
        closeOverlays()
        clipboardScreen = targetScreen
        clipboardVisible = shouldOpen
    }

    function toggleTrayMenu(item, screenName, rightOffset) {
        const sameMenu = trayMenuVisible && trayMenuHandle === item.menu
        closeOverlays()

        if (sameMenu)
            return

        trayMenuHandle = item.menu
        trayMenuTitle = item.title || item.tooltipTitle || item.id || "Application"
        trayMenuIcon = item.icon || ""
        trayMenuScreen = screenName || ""
        trayMenuRightOffset = Math.max(outerGapFallback(), rightOffset || 0)
        trayMenuVisible = true
    }

    function outerGapFallback() {
        return 2
    }

    function closeOverlays() {
        launcherVisible = false
        clipboardVisible = false
        emojiVisible = false
        selectorVisible = false
        notificationCenterVisible = false
        notificationPreviewVisible = false
        powerMenuVisible = false
        clockMenuVisible = false
        settingsVisible = false
        quickControlVisible = false
        trayMenuVisible = false
        networkVisible = false
    }


    function toggleEmoji() {
        const shouldOpen = !emojiVisible
        closeOverlays()
        emojiVisible = shouldOpen
    }
}
