#!/bin/bash
sed -i '/import "notifications" as Notifications/a \import "emoji" as Emoji' quickshell/shell.qml
sed -i '/LazyLoader {/i \    LazyLoader {\n        active: UiState.emojiVisible\n        component: Component { Emoji.EmojiPicker {} }\n    }\n' quickshell/shell.qml
