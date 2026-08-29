#!/bin/bash
sed -i 's/text: delegateRoot.modelData.char/text: delegateRoot.modelData.char || "?"/g' quickshell/emoji/EmojiPicker.qml
