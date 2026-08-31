#!/bin/bash

EXEC_STR="$1"
DESKTOP_ID="$2"
APP_NAME="$3"

echo -e "\e[1;36m====================================\e[0m"
echo -e "\e[1;36m       App Uninstaller Wizard       \e[0m"
echo -e "\e[1;36m====================================\e[0m\n"

if [ -z "$EXEC_STR" ] && [ -z "$DESKTOP_ID" ]; then
    echo -e "\e[1;31mError:\e[0m No executable or desktop file provided."
    read -p "Press Enter to exit..."
    exit 1
fi

# Clean executable string (remove %u, %U, %f, %F, quotes)
CLEAN_EXEC=$(echo "$EXEC_STR" | sed 's/%[a-zA-Z]//g' | tr -d '"' | tr -d "'")
CMD=$(echo "$CLEAN_EXEC" | awk '{print $1}')
CMD_BASENAME=$(basename "$CMD" 2>/dev/null)

# Locate the .desktop file
DESKTOP_FILE=""
if [ -n "$DESKTOP_ID" ]; then
    DESKTOP_FILE=$(find ~/.local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications /usr/local/share/applications -name "$DESKTOP_ID" 2>/dev/null | head -n 1)
fi

echo -e "Application:      \e[1;32m${APP_NAME:-$DESKTOP_ID}\e[0m"
[ -n "$DESKTOP_FILE" ] && echo -e "Desktop Entry:    \e[1;30m$DESKTOP_FILE\e[0m"
[ -n "$CMD" ] && echo -e "Exec Command:     \e[1;30m$CLEAN_EXEC\e[0m"
echo ""

# Edge Case 1: Kill running instances if process is active
if [ -n "$CMD_BASENAME" ] && pgrep -x "$CMD_BASENAME" > /dev/null 2>&1; then
    echo -e "\e[1;33mWarning:\e[0m Running instances of '$CMD_BASENAME' detected."
    read -p "Kill them before uninstalling? [Y/n]: " KILL_APP
    if [[ ! "$KILL_APP" =~ ^[Nn]$ ]]; then
        killall "$CMD_BASENAME" 2>/dev/null
        sleep 1
        echo "Processes terminated."
    fi
    echo ""
fi

# Edge Case 2: Waydroid Android App
if [[ "$DESKTOP_ID" == waydroid.* ]] || [[ "$CMD" == "waydroid" ]]; then
    WAYDROID_PKG=""
    if [[ "$DESKTOP_ID" == waydroid.* ]]; then
        WAYDROID_PKG="${DESKTOP_ID#waydroid.}"
        WAYDROID_PKG="${WAYDROID_PKG%.desktop}"
    fi
    echo -e "Type: \e[1;34mWaydroid Android Application ($WAYDROID_PKG)\e[0m"
    if [ -n "$WAYDROID_PKG" ]; then
        read -p "Uninstall Android package '$WAYDROID_PKG' via Waydroid? [Y/n]: " CONFIRM_WAYDROID
        if [[ ! "$CONFIRM_WAYDROID" =~ ^[Nn]$ ]]; then
            waydroid app remove "$WAYDROID_PKG"
            [ -n "$DESKTOP_FILE" ] && rm -f "$DESKTOP_FILE"
            echo "Waydroid application uninstalled."
        fi
    fi
    read -p "Press Enter to exit..."
    exit 0
fi

# Edge Case 3: Flatpak App
if [[ "$CMD" == "flatpak" ]] || [[ "$DESKTOP_FILE" == *"/flatpak/"* ]]; then
    APP_ID=""
    if [[ "$CMD" == "flatpak" ]]; then
        APP_ID=$(echo "$CLEAN_EXEC" | awk '{for(i=1;i<=NF;i++) if ($i=="run") print $(i+1)}')
    fi
    if [ -z "$APP_ID" ] && [ -n "$DESKTOP_ID" ]; then
        APP_ID="${DESKTOP_ID%.desktop}"
    fi
    echo -e "Type: \e[1;34mFlatpak Application ($APP_ID)\e[0m"
    read -p "Uninstall Flatpak package '$APP_ID'? [Y/n]: " CONFIRM_FLATPAK
    if [[ ! "$CONFIRM_FLATPAK" =~ ^[Nn]$ ]]; then
        flatpak uninstall -y "$APP_ID"
        if [ $? -eq 0 ]; then
            if [ -d "$HOME/.var/app/$APP_ID" ]; then
                echo -e "\n\e[1;33mDelete leftover Flatpak data in ~/.var/app/$APP_ID? (y/N)\e[0m"
                read -r DELDATA
                if [[ "$DELDATA" =~ ^[Yy]$ ]]; then
                    rm -rf "$HOME/.var/app/$APP_ID"
                    echo "Deleted flatpak user data."
                fi
            fi
        fi
    fi
    read -p "Press Enter to exit..."
    exit 0
fi

# Edge Case 4: Package Manager (Pacman / Yay / AUR)
PKG_NAME=""

# First try: Query ownership of the .desktop file itself (most accurate for packaged apps)
if [ -n "$DESKTOP_FILE" ]; then
    PKG_INFO=$(pacman -Qo "$DESKTOP_FILE" 2>/dev/null)
    if [ $? -eq 0 ]; then
        PKG_NAME=$(echo "$PKG_INFO" | awk '{print $5}')
    fi
fi

# Second try: Query ownership of the executable binary
BIN_PATH=""
if [ -z "$PKG_NAME" ] && [ -n "$CMD" ]; then
    BIN_PATH=$(which "$CMD" 2>/dev/null || type -p "$CMD" 2>/dev/null)
    if [ -n "$BIN_PATH" ]; then
        PKG_INFO=$(pacman -Qo "$BIN_PATH" 2>/dev/null)
        if [ $? -eq 0 ]; then
            PKG_NAME=$(echo "$PKG_INFO" | awk '{print $5}')
        fi
    fi
fi

# Guard against accidental removal of critical core system packages
PROTECTED_PKGS=("bash" "coreutils" "glibc" "systemd" "linux" "filesystem" "util-linux" "hyprland" "quickshell" "kitty" "pacman" "yay" "sudo" "polkit")
IS_PROTECTED=0
for p in "${PROTECTED_PKGS[@]}"; do
    if [ "$PKG_NAME" == "$p" ]; then
        IS_PROTECTED=1
        break
    fi
done

if [ -n "$PKG_NAME" ] && [ "$IS_PROTECTED" -eq 0 ]; then
    echo -e "Type: \e[1;34mManaged Package ($PKG_NAME)\e[0m\n"
    read -p "Uninstall '$PKG_NAME' with dependencies? [Y/n]: " CONFIRM_PKG
    if [[ ! "$CONFIRM_PKG" =~ ^[Nn]$ ]]; then
        if command -v yay >/dev/null 2>&1; then
            echo -e "\e[1;33mExecuting: yay -Rns $PKG_NAME\e[0m"
            yay -Rns "$PKG_NAME"
        else
            echo -e "\e[1;33mExecuting: sudo pacman -Rns $PKG_NAME\e[0m"
            sudo pacman -Rns "$PKG_NAME"
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "\n\e[1;31mPackage manager returned an error.\e[0m"
            read -p "Press Enter to exit..."
            exit 1
        fi
    else
        echo "Uninstallation cancelled."
        read -p "Press Enter to exit..."
        exit 0
    fi
else
    # Edge Case 5: Unmanaged Local or System Binary / AppImage
    echo -e "Type: \e[1;34mUnmanaged Executable / Local Application\e[0m\n"
    if [ -z "$BIN_PATH" ] && [ -n "$CMD" ]; then
        BIN_PATH=$(which "$CMD" 2>/dev/null || type -p "$CMD" 2>/dev/null)
    fi
    
    if [ -n "$BIN_PATH" ]; then
        echo -e "Binary Location: \e[1;33m$BIN_PATH\e[0m"
        if [[ "$BIN_PATH" == "$HOME"* ]]; then
            read -p "Delete user binary file ($BIN_PATH)? [y/N]: " DELBIN
            if [[ "$DELBIN" =~ ^[Yy]$ ]]; then
                rm -f "$BIN_PATH"
                echo "Deleted $BIN_PATH."
            fi
        elif [[ "$BIN_PATH" == "/usr/local/"* ]] || [[ "$BIN_PATH" == "/opt/"* ]]; then
            read -p "Delete system binary ($BIN_PATH) with sudo? [y/N]: " DELBIN
            if [[ "$DELBIN" =~ ^[Yy]$ ]]; then
                sudo rm -rf "$BIN_PATH"
                echo "Deleted $BIN_PATH."
            fi
        fi
    fi
    
    # Cleanup desktop file
    if [ -n "$DESKTOP_FILE" ]; then
        if [[ "$DESKTOP_FILE" == "$HOME"* ]]; then
            read -p "Delete user desktop entry ($DESKTOP_FILE)? [Y/n]: " DELDESK
            if [[ ! "$DELDESK" =~ ^[Nn]$ ]]; then
                rm -f "$DESKTOP_FILE"
                echo "Deleted desktop entry."
            fi
        else
            read -p "Delete system desktop entry ($DESKTOP_FILE) with sudo? [y/N]: " DELDESK
            if [[ "$DELDESK" =~ ^[Yy]$ ]]; then
                sudo rm -f "$DESKTOP_FILE"
                echo "Deleted system desktop entry."
            fi
        fi
    fi
fi

# Edge Case 6: Deep Config & Cache Cleanup (XDG Standard)
echo -e "\n\e[1;36mScanning for application configuration and data directories...\e[0m"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

declare -a TARGET_NAMES
[ -n "$PKG_NAME" ] && TARGET_NAMES+=("$PKG_NAME")
[ -n "$CMD_BASENAME" ] && TARGET_NAMES+=("$CMD_BASENAME")
[ -n "$APP_NAME" ] && TARGET_NAMES+=("$APP_NAME")
if [ -n "$DESKTOP_ID" ]; then
    TARGET_NAMES+=("${DESKTOP_ID%.desktop}")
    # Handle domain prefixes like in.codelif.Whatevr or com.ktechpit.whatsie
    RAW_BASE="${DESKTOP_ID%.desktop}"
    LAST_SEG="${RAW_BASE##*.}"
    [ -n "$LAST_SEG" ] && TARGET_NAMES+=("$LAST_SEG")
fi

VALID_TARGETS=()
for name in "${TARGET_NAMES[@]}"; do
    cleaned=$(echo "$name" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    if [[ ${#cleaned} -ge 3 ]]; then
        VALID_TARGETS+=("$cleaned")
    fi
done

if [ ${#VALID_TARGETS[@]} -gt 0 ]; then
    FOUND_DIRS=()
    SEARCH_BASE_DIRS=("$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME")
    
    for base_dir in "${SEARCH_BASE_DIRS[@]}"; do
        if [ -d "$base_dir" ]; then
            for target in "${VALID_TARGETS[@]}"; do
                while IFS= read -r match; do
                    if [ -n "$match" ] && [ -d "$match" ]; then
                        # Exclude root config dirs or critical standard folders
                        bname=$(basename "$match")
                        if [ "$bname" != "hypr" ] && [ "$bname" != "quickshell" ] && [ "$bname" != "kitty" ]; then
                            FOUND_DIRS+=("$match")
                        fi
                    fi
                done < <(find "$base_dir" -maxdepth 1 -type d -iname "*$target*" 2>/dev/null)
            done
        fi
    done

    if [ ${#FOUND_DIRS[@]} -gt 0 ]; then
        UNIQUE_DIRS=($(printf "%s\n" "${FOUND_DIRS[@]}" | sort -u))
        echo -e "\nFound application data directories:"
        for dir in "${UNIQUE_DIRS[@]}"; do
            echo -e "\e[1;31m  - $dir\e[0m"
        done
        
        read -p "Delete all the above application data directories? [y/N]: " DELCONF
        if [[ "$DELCONF" =~ ^[Yy]$ ]]; then
            for dir in "${UNIQUE_DIRS[@]}"; do
                rm -rf "$dir"
            done
            echo "Successfully cleaned application data."
        else
            echo "Preserved application data."
        fi
    fi
fi

# Refresh XDG desktop database so launcher drops uninstalled app immediately
update-desktop-database ~/.local/share/applications 2>/dev/null

echo -e "\n\e[1;32mUninstallation Finished!\e[0m"
read -p "Press Enter to exit..."
