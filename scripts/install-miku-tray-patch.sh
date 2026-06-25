#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

echo "Creating the tray patch script..."
cat << 'INNER_EOF' > /usr/local/bin/patch-antigravity-tray.sh
#!/bin/bash
ASAR="/opt/Antigravity/resources/app.asar"
TMP_DIR="/tmp/antigravity-asar-patch"
TMP_ASAR="/tmp/app.asar.patched"
SVG_FILE="/home/dipak/.local/share/icons/YAMIS-enlarged/apps/scalable/antigravity.svg"

rm -rf "$TMP_DIR" "$TMP_ASAR"
sudo -u dipak npx -y asar extract "$ASAR" "$TMP_DIR"

rsvg-convert -w 16 -h 16 "$SVG_FILE" -o "$TMP_DIR/trayTemplate.png"
rsvg-convert -w 32 -h 32 "$SVG_FILE" -o "$TMP_DIR/trayTemplate@2x.png"
rsvg-convert -w 48 -h 48 "$SVG_FILE" -o "$TMP_DIR/icon.png"

sudo -u dipak npx -y asar pack "$TMP_DIR" "$TMP_ASAR"
mv "$TMP_ASAR" "$ASAR"
rm -rf "$TMP_DIR"
INNER_EOF

chmod +x /usr/local/bin/patch-antigravity-tray.sh

echo "Creating the pacman hook for automatic patching on updates..."
mkdir -p /etc/pacman.d/hooks
cat << 'INNER_EOF' > /etc/pacman.d/hooks/antigravity-tray-patch.hook
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = antigravity
Target = antigravity-bin

[Action]
Description = Patching Antigravity tray icon to use the monochrome logo...
When = PostTransaction
Exec = /usr/local/bin/patch-antigravity-tray.sh
INNER_EOF

echo "Running the patcher for the first time..."
/usr/local/bin/patch-antigravity-tray.sh

echo "Done! The tray icon is permanently patched!"
