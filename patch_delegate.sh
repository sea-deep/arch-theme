#!/bin/bash
sed -i '/font.pixelSize: 22/a \                        Component.onCompleted: if(index === 0) console.log("First delegate char:", delegateRoot.modelData.char)' quickshell/emoji/EmojiPicker.qml
