import QtQuick
import Quickshell
import "theme"

Item {
    Component.onCompleted: {
        console.log("Bar height:", Theme.barHeight)
        console.log("Caffeine:", UiState.caffeineEnabled)
        Qt.quit()
    }
}
