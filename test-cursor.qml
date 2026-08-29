import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Process {
        id: posProc
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
                Quickshell.exit(0)
            }
        }
        Component.onCompleted: running = true
    }
}
