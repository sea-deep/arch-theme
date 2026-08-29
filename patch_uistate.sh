#!/bin/bash
# Remove the bad lines at the end
sed -i '/function toggleEmoji()/,$d' quickshell/theme/UiState.qml
# Now it ends with "}"
# We want to insert toggleEmoji BEFORE that last brace.
sed -i '/^}$/d' quickshell/theme/UiState.qml
cat << 'INNER_EOF' >> quickshell/theme/UiState.qml

    function toggleEmoji() {
        const shouldOpen = !emojiVisible
        closeOverlays()
        emojiVisible = shouldOpen
    }
}
INNER_EOF
