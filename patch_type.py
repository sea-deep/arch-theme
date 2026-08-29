import re
with open("quickshell/emoji/EmojiPicker.qml", "r") as f:
    content = f.read()

# Replace copyProcess calls
old_call1 = """copyProcess.command = ["wl-copy", currentItem.modelData.char]
                            copyProcess.running = true"""
new_call1 = """Quickshell.execDetached([Quickshell.shellPath("scripts/type-emoji.sh"), currentItem.modelData.char])"""

old_call2 = """copyProcess.command = ["wl-copy", delegateRoot.modelData.char]
                            copyProcess.running = true"""
new_call2 = """Quickshell.execDetached([Quickshell.shellPath("scripts/type-emoji.sh"), delegateRoot.modelData.char])"""

content = content.replace(old_call1, new_call1)
content = content.replace(old_call2, new_call2)

# Remove Process block
content = re.sub(r'Process \{\s*id: copyProcess.*?\}\s*\}', '}', content, flags=re.DOTALL)

with open("quickshell/emoji/EmojiPicker.qml", "w") as f:
    f.write(content)
