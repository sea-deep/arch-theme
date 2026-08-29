#!/bin/bash

EXEC_STR="$1"
DESKTOP_ID="$2"

echo -e "\e[1;36m====================================\e[0m"
echo -e "\e[1;36m       App Uninstaller Wizard       \e[0m"
echo -e "\e[1;36m====================================\e[0m\n"

if [ -z "$EXEC_STR" ]; then
    echo -e "\e[1;31mError:\e[0m No executable provided."
    read -p "Press Enter to exit..."
    exit 1
fi

CMD=$(echo "$EXEC_STR" | awk '{print $1}')
CMD=$(echo "$CMD" | tr -d '"' | tr -d "'")
CMD_BASENAME=$(basename "$CMD")

echo -e "Target Executable: \e[1;32m$CMD\e[0m"
if [ -n "$DESKTOP_ID" ]; then
    echo -e "Target Desktop ID: \e[1;32m$DESKTOP_ID\e[0m"
fi
echo ""

# Edge Case 1: Kill running instances
if pgrep -x "$CMD_BASENAME" > /dev/null; then
    echo -e "\e[1;33mWarning:\e[0m Instances of $CMD_BASENAME are currently running."
    read -p "Kill them before uninstalling? [y/N]: " KILL_APP
    if [[ "$KILL_APP" =~ ^[Yy]$ ]]; then
        killall "$CMD_BASENAME" 2>/dev/null
        sleep 1
        echo "Killed."
    fi
    echo ""
fi

# Locate the .desktop file for cleanup
DESKTOP_FILE=""
if [ -n "$DESKTOP_ID" ]; then
    DESKTOP_FILE=$(find ~/.local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications /usr/local/share/applications -name "$DESKTOP_ID" 2>/dev/null | head -n 1)
    if [ -n "$DESKTOP_FILE" ]; then
        echo -e "Found Desktop Entry: \e[1;30m$DESKTOP_FILE\e[0m"
    fi
fi

# Flatpak Handling
if [[ "$CMD" == "flatpak" ]]; then
    APP_ID=$(echo "$EXEC_STR" | awk '{print $3}')
    echo -e "Type: \e[1;34mFlatpak App ($APP_ID)\e[0m"
    echo -e "\nInvoking Flatpak Uninstaller..."
    flatpak uninstall "$APP_ID"
    
    if [ $? -eq 0 ]; then
        echo -e "\n\e[1;33mDelete leftover Flatpak data in ~/.var/app/$APP_ID? (y/N)\e[0m"
        read -r DELDATA
        if [[ "$DELDATA" =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.var/app/$APP_ID"
            echo "Deleted flatpak app data."
        fi
    fi
    read -p "Press Enter to exit..."
    exit 0
fi

# Resolve actual binary
BIN_PATH=$(which "$CMD" 2>/dev/null)
if [ -z "$BIN_PATH" ]; then
    BIN_PATH=$(which "${EXEC_STR%.desktop}" 2>/dev/null)
    if [ -z "$BIN_PATH" ]; then
        echo -e "\e[1;31mError:\e[0m Could not resolve executable '$CMD' in PATH."
        read -p "Press Enter to exit..."
        exit 1
    fi
fi
echo -e "Binary Path: \e[1;30m$BIN_PATH\e[0m"

# Edge Case 2: Package Manager vs Local File
PKG_INFO=$(pacman -Qo "$BIN_PATH" 2>/dev/null)

if [ $? -eq 0 ]; then
    # Managed by pacman/yay
    PKG_NAME=$(echo "$PKG_INFO" | awk '{print $5}')
    echo -e "Type: \e[1;34mManaged Package ($PKG_NAME)\e[0m\n"
    
    echo -e "\e[1;33mExecuting: yay -Rnsc $PKG_NAME\e[0m"
    yay -Rnsc "$PKG_NAME"
    
    if [ $? -ne 0 ]; then
        echo -e "\n\e[1;31mAborted.\e[0m"
        read -p "Press Enter to exit..."
        exit 1
    fi
else
    # Not managed by pacman (e.g. AppImage, local script, manual install)
    echo -e "Type: \e[1;34mUnmanaged Local Executable\e[0m\n"
    if [[ "$BIN_PATH" == "$HOME"* ]]; then
        echo -e "\e[1;33mWarning:\e[0m This executable is not managed by pacman."
        echo -e "It is located in your home directory: \e[1;31m$BIN_PATH\e[0m"
        read -p "Would you like to permanently delete this file? [y/N]: " DELBIN
        if [[ "$DELBIN" =~ ^[Yy]$ ]]; then
            rm -f "$BIN_PATH"
            echo "Deleted $BIN_PATH."
        else
            echo "Aborted."
            read -p "Press Enter to exit..."
            exit 1
        fi
    else
        echo -e "\e[1;31mError:\e[0m Executable is located in a system directory ($BIN_PATH) but not managed by pacman."
        echo "Please remove it manually."
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

# Cleanup Desktop File
if [ -n "$DESKTOP_FILE" ] && [[ "$DESKTOP_FILE" == "$HOME"* ]]; then
    echo -e "\n\e[1;33mFound local desktop file:\e[0m $DESKTOP_FILE"
    read -p "Delete it to remove it from the launcher? [Y/n]: " DELDESK
    if [[ ! "$DELDESK" =~ ^[Nn]$ ]]; then
        rm -f "$DESKTOP_FILE"
        echo "Deleted desktop entry."
    fi
fi

# Edge Case 3: Deep Config Cleanup (XDG Standard)
echo -e "\n\e[1;36mScanning for leftover XDG configuration and data directories...\e[0m"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Gather potential names for the application (package name, binary name, desktop ID)
declare -a TARGET_NAMES
TARGET_NAMES+=("$PKG_NAME")
TARGET_NAMES+=("$CMD_BASENAME")
if [ -n "$DESKTOP_ID" ]; then
    TARGET_NAMES+=("${DESKTOP_ID%.desktop}")
fi

# Remove empty or dangerously short names
VALID_TARGETS=()
for name in "${TARGET_NAMES[@]}"; do
    if [[ ${#name} -ge 3 ]]; then
        VALID_TARGETS+=("$name")
    fi
done

if [ ${#VALID_TARGETS[@]} -eq 0 ]; then
    echo "No valid search terms found to safely scan for config directories."
else
    FOUND_DIRS=()
    SEARCH_BASE_DIRS=("$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME")
    
    for base_dir in "${SEARCH_BASE_DIRS[@]}"; do
        if [ -d "$base_dir" ]; then
            for target in "${VALID_TARGETS[@]}"; do
                # Strict match: find directories exactly matching the target name (case-insensitive)
                while IFS= read -r match; do
                    if [ -n "$match" ]; then
                        FOUND_DIRS+=("$match")
                    fi
                done < <(find "$base_dir" -maxdepth 1 -type d -iname "$target" 2>/dev/null)
            done
        fi
    done

    # Remove duplicates from FOUND_DIRS
    if [ ${#FOUND_DIRS[@]} -gt 0 ]; then
        UNIQUE_DIRS=($(printf "%s\n" "${FOUND_DIRS[@]}" | sort -u))
        
        echo -e "\nFound the following XDG application directories:"
        for dir in "${UNIQUE_DIRS[@]}"; do
            echo -e "\e[1;31m  - $dir\e[0m"
        done
        
        echo -e "\n\e[1;31mDANGER:\e[0m Delete all the above directories? THIS CANNOT BE UNDONE. [y/N]: \c"
        read -r DELCONF
        if [[ "$DELCONF" =~ ^[Yy]$ ]]; then
            for dir in "${UNIQUE_DIRS[@]}"; do
                rm -rf "$dir"
            done
            echo "Successfully wiped all configuration and data leftovers."
        else
            echo "Skipped config deletion."
        fi
    else
        echo "No standard XDG configuration or data directories found for this application."
    fi
fi

echo -e "\n\e[1;32mUninstallation Complete!\e[0m"
sleep 2
