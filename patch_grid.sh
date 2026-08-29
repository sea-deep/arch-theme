#!/bin/bash
sed -i '/GridView {/a \                onCountChanged: console.log("GridView count:", count)' quickshell/emoji/EmojiPicker.qml
