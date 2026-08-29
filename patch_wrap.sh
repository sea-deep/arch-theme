#!/bin/bash
sed -i '/GridView {/i \            Item {\n                Layout.fillWidth: true\n                Layout.fillHeight: true' quickshell/emoji/EmojiPicker.qml
sed -i 's/GridView {/GridView {\n                    anchors.fill: parent/' quickshell/emoji/EmojiPicker.qml
sed -i 's/Layout.fillWidth: true//' quickshell/emoji/EmojiPicker.qml
sed -i 's/Layout.fillHeight: true//' quickshell/emoji/EmojiPicker.qml
# We just removed ALL Layout.fillWidth/Height from the file! That's bad.
