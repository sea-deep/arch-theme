import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    collapseWhenEmpty: true

    // Bind securely to the active toplevel
    property string activeTitle: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""

    isEmpty: activeTitle === ""
    
    // Match max-length: 40 character approx width for monospace with horizontal padding
    implicitWidth: Math.min(titleText.implicitWidth + Theme.pillPaddingHoriz * 2, 400)
    
    Text {
        id: titleText
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - Theme.pillPaddingHoriz * 2)
        
        text: root.activeTitle
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
