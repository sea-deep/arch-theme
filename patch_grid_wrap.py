import re

with open("quickshell/emoji/EmojiPicker.qml", "r") as f:
    content = f.read()

# Find GridView
grid_start = content.find("GridView {")
if grid_start != -1:
    # Wrap it in Item
    # Replace Layout.fillWidth and Layout.fillHeight inside GridView with anchors.fill: parent
    
    # Actually, let's just replace the GridView block
    old_grid = """            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true"""
    
    new_grid = """            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                GridView {
                    id: grid
                    anchors.fill: parent"""
    
    content = content.replace(old_grid, new_grid)
    
    # Now we need to add the closing brace for Item
    # The GridView ends before "// Categories"
    categories_start = content.find("// Categories")
    if categories_start != -1:
        # insert closing brace for Item
        content = content[:categories_start] + "            }\n\n            " + content[categories_start:]

with open("quickshell/emoji/EmojiPicker.qml", "w") as f:
    f.write(content)
