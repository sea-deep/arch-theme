import QtQuick
import "quickshell/emoji/EmojiData.js" as EmojiData
Window {
    Component.onCompleted: {
        var ems = EmojiData.categories["Smileys & Emotion"]
        console.log("Len:", ems.length)
        if(ems.length > 0) {
            console.log("Item 0 char:", ems[0].char, "name:", ems[0].name)
        }
    }
}
