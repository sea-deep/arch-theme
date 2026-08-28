import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    property bool isRecording: false
    
    collapseWhenEmpty: true
    isEmpty: !isRecording
    
    implicitWidth: isRecording ? (layout.implicitWidth + Theme.pillPadding * 2) : 0
    visible: isRecording
    
    Process {
        id: recProc
        command: ["sh", "-c", "pgrep -x wf-recorder >/dev/null && echo 'recording' || echo ''"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.isRecording = data.trim() === "recording"
            }
        }
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: recProc.running = true
    }
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        
        Text {
            text: "●"
            color: blinkTimer.blinkState ? Theme.red : Theme.bgDark
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            visible: root.isRecording
            
            Timer {
                id: blinkTimer
                interval: 800
                running: root.isRecording
                repeat: true
                property bool blinkState: false
                onTriggered: blinkState = !blinkState
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.exec("sh ~/.config/hypr/toggle_recorder.sh")
    }
}
