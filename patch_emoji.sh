#!/bin/bash
sed -i '/flatEmojis = list/a \        console.log("Generated flatEmojis: " + flatEmojis.length)' quickshell/emoji/EmojiPicker.qml
