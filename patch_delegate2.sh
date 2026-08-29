#!/bin/bash
sed -i 's/console.log("First delegate char:".*)/console.log("First delegate char:", delegateRoot.modelData.char, "name:", delegateRoot.modelData.name)/' quickshell/emoji/EmojiPicker.qml
