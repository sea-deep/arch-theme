import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme" as Theme
import "../components" as Components

Components.Pill {
    id: root
    
    collapseWhenEmpty: true
    isEmpty: !Hyprland.focusedWindow || Hyprland.focusedWindow.title === ""
    
    implicitWidth: Math.min(titleText.implicitWidth + Theme.pillPadding * 2, 300)
    
    Text {
        id: titleText
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - Theme.pillPadding * 2)
        
        text: Hyprland.focusedWindow ? Hyprland.focusedWindow.title : ""
        color: Theme.fgMuted
        font.family: Theme.fontFamilySans
        font.pixelSize: 12
        
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
