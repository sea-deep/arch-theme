#!/bin/bash
sed -i 's/property var flatEmojis: \[\]/property var flatEmojis: \[\]\n    property var displayEmojis: \[\]/g' quickshell/emoji/EmojiPicker.qml
sed -i 's/flatEmojis = list/flatEmojis = list\n        displayEmojis = list/g' quickshell/emoji/EmojiPicker.qml
sed -i 's/onTextChanged: root.searchQuery = text.toLowerCase()/onTextChanged: {\n                            root.searchQuery = text.toLowerCase()\n                            if (root.searchQuery === "") {\n                                root.displayEmojis = root.flatEmojis\n                            } else {\n                                root.displayEmojis = root.flatEmojis.filter(e => e.name.toLowerCase().indexOf(root.searchQuery) !== -1)\n                            }\n                        }/g' quickshell/emoji/EmojiPicker.qml
sed -i 's/model: root.searchQuery === "" ? root.flatEmojis : root.flatEmojis.filter(function(e) {/model: root.displayEmojis\n                \/\/ /g' quickshell/emoji/EmojiPicker.qml
sed -i 's/return e.name.toLowerCase().indexOf(root.searchQuery) !== -1/\/\/ /g' quickshell/emoji/EmojiPicker.qml
sed -i 's/})/\/\/ /g' quickshell/emoji/EmojiPicker.qml
