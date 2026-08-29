#!/bin/bash
sed -i '/flatEmojis = list/a \        console.log("first flatEmoji:", flatEmojis[0].char, flatEmojis[0].name)' quickshell/emoji/EmojiPicker.qml
