#!/bin/bash

# Check if rofi is already running (toggle behavior)
if pgrep -x rofi > /dev/null; then
    pkill -x rofi
    exit 0
fi

# Define the available TLP power modes with Nerd Font icons
options="󰓅     performance\n󰾅     balanced\n󰌪     power-saver"

# Use rofi to display the options and get the user's selection.
# We inject a northeast dropdown location and disable the search bar (inputbar).
selected=$(echo -e "$options" | rofi -dmenu -i -p "Power Profile" \
    -theme-str 'window {width: 250px; location: northeast; anchor: northeast; x-offset: -75px; y-offset: 5px; border-radius: 12px; border: 2px; border-color: #39c5bb;}' \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'listview {lines: 3;}' \
    -theme-str 'element { children: [ element-text ]; }' \
    -theme-str 'element selected {background-color: #39c5bb; text-color: #1a1b26;}')

# If the user selected a valid option, apply it
if [ -n "$selected" ]; then
    # Extract the word at the end of the line (e.g., 'performance', 'power-saver')
    profile=$(echo "$selected" | grep -oE '[a-z-]+$')

    if [ -n "$profile" ]; then
        # We use kitty to prompt for sudo since tlp requires root permissions.
        kitty --class tlp_updater -T "Changing TLP to $profile" -e bash -c "sudo tlp $profile; echo ''; read -p 'Press Enter to close...'"
    fi
fi
