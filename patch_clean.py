with open("quickshell/emoji/EmojiPicker.qml", "r") as f:
    lines = f.readlines()
with open("quickshell/emoji/EmojiPicker.qml", "w") as f:
    for line in lines:
        if "model: root.displayEmojis" in line:
            f.write("                model: root.displayEmojis\n")
        elif line.strip() == "//":
            pass
        elif line.strip() == "//" or line.strip() == "//" or line.strip() == "//":
            pass
        else:
            f.write(line)
