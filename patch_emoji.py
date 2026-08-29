with open("quickshell/emoji/EmojiPicker.qml", "r") as f:
    content = f.read()

content = content.replace("displayEmojis = list", "displayEmojis = [].concat(list)")
content = content.replace('root.displayEmojis = root.flatEmojis', 'root.displayEmojis = [].concat(root.flatEmojis)')

# Also add the fallback for visible changing
vis_old = """    onVisibleChanged: {
        if (visible) {
            cursorX = -1
            cursorY = -1
            searchQuery = ""
            searchInput.text = ""
            posProc.running = true"""

vis_new = """    onVisibleChanged: {
        if (visible) {
            cursorX = -1
            cursorY = -1
            searchQuery = ""
            searchInput.text = ""
            root.displayEmojis = [].concat(root.flatEmojis)
            posProc.running = true"""

content = content.replace(vis_old, vis_new)

with open("quickshell/emoji/EmojiPicker.qml", "w") as f:
    f.write(content)
