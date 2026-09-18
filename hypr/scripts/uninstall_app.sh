#!/bin/bash
# ==============================================================================
# sea-deep Universal App Uninstaller Wizard
# Fully handles: Pacman / Yay / AUR, Flatpak, Waydroid, Local/Orphaned apps,
# and deep XDG config/cache/state + Quickshell launcher cleanup.
# 100% Pure Bash / POSIX standards.
# ==============================================================================

EXEC_STR="$1"
DESKTOP_ID="$2"
APP_NAME="$3"

echo -e "\e[1;36m====================================\e[0m"
echo -e "\e[1;36m       App Uninstaller Wizard       \e[0m"
echo -e "\e[1;36m====================================\e[0m\n"

if [ -z "$EXEC_STR" ] && [ -z "$DESKTOP_ID" ] && [ -z "$APP_NAME" ]; then
    echo -e "\e[1;31mError:\e[0m No executable, desktop file, or application name provided."
    read -p "Press Enter to exit..."
    exit 1
fi

# Clean executable string (remove %u, %U, %f, %F, quotes)
CLEAN_EXEC=$(echo "$EXEC_STR" | sed 's/%[a-zA-Z]//g' | tr -d '"' | tr -d "'")
CMD=$(echo "$CLEAN_EXEC" | awk '{print $1}')
CMD_BASENAME=""
[ -n "$CMD" ] && CMD_BASENAME=$(basename "$CMD" 2>/dev/null)

# Standard search directories for .desktop files
DESKTOP_DIRS=(
    "$HOME/.local/share/applications"
    "/usr/share/applications"
    "/usr/local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
)

# Multi-tiered resolution to locate the .desktop file
DESKTOP_FILE=""

# Strategy 1: Direct file check if DESKTOP_ID is already an absolute path
if [ -n "$DESKTOP_ID" ] && [ -f "$DESKTOP_ID" ]; then
    DESKTOP_FILE="$DESKTOP_ID"
fi

# Strategy 2: Match by DESKTOP_ID in standard directories
if [ -z "$DESKTOP_FILE" ] && [ -n "$DESKTOP_ID" ]; then
    DESKTOP_FILE=$(find "${DESKTOP_DIRS[@]}" -maxdepth 2 -name "$DESKTOP_ID" 2>/dev/null | head -n 1)
    [ -z "$DESKTOP_FILE" ] && DESKTOP_FILE=$(find "${DESKTOP_DIRS[@]}" -maxdepth 2 -name "${DESKTOP_ID%.desktop}.desktop" 2>/dev/null | head -n 1)
    [ -z "$DESKTOP_FILE" ] && DESKTOP_FILE=$(find "${DESKTOP_DIRS[@]}" -maxdepth 2 -iname "${DESKTOP_ID%.desktop}.desktop" 2>/dev/null | head -n 1)
    [ -z "$DESKTOP_FILE" ] && DESKTOP_FILE=$(find "${DESKTOP_DIRS[@]}" -maxdepth 2 -iname "*${DESKTOP_ID%.desktop}*.desktop" 2>/dev/null | head -n 1)
fi

# Strategy 3: Match by CMD_BASENAME
if [ -z "$DESKTOP_FILE" ] && [ -n "$CMD_BASENAME" ]; then
    DESKTOP_FILE=$(find "${DESKTOP_DIRS[@]}" -maxdepth 2 -iname "${CMD_BASENAME}.desktop" 2>/dev/null | head -n 1)
    [ -z "$DESKTOP_FILE" ] && DESKTOP_FILE=$(find "${DESKTOP_DIRS[@]}" -maxdepth 2 -iname "*${CMD_BASENAME}*.desktop" 2>/dev/null | head -n 1)
    [ -z "$DESKTOP_FILE" ] && DESKTOP_FILE=$(grep -rnwl -m 1 "Exec=.*${CMD_BASENAME}" "${DESKTOP_DIRS[@]}" 2>/dev/null | head -n 1)
fi

# Strategy 4: Match by APP_NAME
if [ -z "$DESKTOP_FILE" ] && [ -n "$APP_NAME" ]; then
    APP_SLUG=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -d '-')
    DESKTOP_FILE=$(find "${DESKTOP_DIRS[@]}" -maxdepth 2 -iname "*${APP_SLUG}*.desktop" 2>/dev/null | head -n 1)
    [ -z "$DESKTOP_FILE" ] && DESKTOP_FILE=$(grep -rnwli -m 1 "^Name=${APP_NAME}" "${DESKTOP_DIRS[@]}" 2>/dev/null | head -n 1)
fi

# If DESKTOP_FILE was located, backfill missing CMD, CMD_BASENAME, and APP_NAME from it
if [ -n "$DESKTOP_FILE" ] && [ -f "$DESKTOP_FILE" ]; then
    if [ -z "$CMD" ]; then
        RAW_EXEC=$(grep -E "^Exec=" "$DESKTOP_FILE" | head -n 1 | cut -d= -f2-)
        CLEAN_EXEC=$(echo "$RAW_EXEC" | sed 's/%[a-zA-Z]//g' | tr -d '"' | tr -d "'")
        CMD=$(echo "$CLEAN_EXEC" | awk '{print $1}')
        [ -n "$CMD" ] && CMD_BASENAME=$(basename "$CMD" 2>/dev/null)
    fi
    if [ -z "$APP_NAME" ]; then
        APP_NAME=$(grep -E "^Name=" "$DESKTOP_FILE" | head -n 1 | cut -d= -f2-)
    fi
fi

# Resolve binary path and verify if it actually exists on the filesystem
BIN_PATH=""
BIN_EXISTS=0
if [ -n "$CMD" ]; then
    if [ -f "$CMD" ] || [ -x "$CMD" ]; then
        BIN_PATH="$CMD"
        BIN_EXISTS=1
    else
        BIN_PATH=$(which "$CMD_BASENAME" 2>/dev/null || type -p "$CMD_BASENAME" 2>/dev/null)
        [ -n "$BIN_PATH" ] && [ -e "$BIN_PATH" ] && BIN_EXISTS=1
    fi
fi

echo -e "Application:      \e[1;32m${APP_NAME:-${DESKTOP_ID:-$CMD_BASENAME}}\e[0m"
[ -n "$DESKTOP_FILE" ] && echo -e "Desktop Entry:    \e[1;30m$DESKTOP_FILE\e[0m"
[ -n "$CLEAN_EXEC" ]   && echo -e "Exec Command:     \e[1;30m$CLEAN_EXEC\e[0m"
if [ "$BIN_EXISTS" -eq 1 ]; then
    echo -e "Binary Path:      \e[1;30m$BIN_PATH\e[0m"
elif [ -n "$CMD" ]; then
    echo -e "Binary Status:    \e[1;33mNot found ($CMD)\e[0m"
fi
echo ""

# Edge Case 1: Terminate running instances
if [ -n "$CMD_BASENAME" ] && pgrep -x "$CMD_BASENAME" > /dev/null 2>&1; then
    echo -e "\e[1;33mWarning:\e[0m Running process '$CMD_BASENAME' detected."
    read -p "Kill running processes before uninstalling? [Y/n]: " KILL_APP
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
    echo -e "Type: \e[1;34mWaydroid Android Application ($WAYDROID_PKG)\e[0m\n"
    if [ -n "$WAYDROID_PKG" ]; then
        read -p "Uninstall Android package '$WAYDROID_PKG' via Waydroid? [Y/n]: " CONFIRM_WAYDROID
        if [[ ! "$CONFIRM_WAYDROID" =~ ^[Nn]$ ]]; then
            waydroid app remove "$WAYDROID_PKG"
            [ -n "$DESKTOP_FILE" ] && rm -f "$DESKTOP_FILE"
            echo -e "\e[1;32m[✓] Waydroid application uninstalled.\e[0m"
        fi
    fi
    read -p "Press Enter to exit..."
    exit 0
fi

# Edge Case 3: Flatpak App
IS_FLATPAK=0
FLATPAK_ID=""
if [[ "$CMD" == "flatpak" ]] || [[ "$DESKTOP_FILE" == *"/flatpak/"* ]]; then
    IS_FLATPAK=1
fi
if [ "$IS_FLATPAK" -eq 0 ] && command -v flatpak >/dev/null 2>&1; then
    # Check if app matches any installed flatpak
    if [ -n "$DESKTOP_ID" ] && flatpak list --app --columns=application 2>/dev/null | grep -qx "${DESKTOP_ID%.desktop}"; then
        IS_FLATPAK=1
        FLATPAK_ID="${DESKTOP_ID%.desktop}"
    fi
fi

if [ "$IS_FLATPAK" -eq 1 ]; then
    if [ -z "$FLATPAK_ID" ]; then
        if [[ "$CMD" == "flatpak" ]]; then
            FLATPAK_ID=$(echo "$CLEAN_EXEC" | awk '{for(i=1;i<=NF;i++) if ($i=="run") print $(i+1)}')
        fi
        if [ -z "$FLATPAK_ID" ] && [ -n "$DESKTOP_ID" ]; then
            FLATPAK_ID="${DESKTOP_ID%.desktop}"
        fi
        if [ -z "$FLATPAK_ID" ] && [ -n "$DESKTOP_FILE" ]; then
            FLATPAK_ID=$(basename "$DESKTOP_FILE" .desktop)
        fi
    fi

    echo -e "Type: \e[1;34mFlatpak Application ($FLATPAK_ID)\e[0m\n"
    read -p "Uninstall Flatpak package '$FLATPAK_ID'? [Y/n]: " CONFIRM_FLATPAK
    if [[ ! "$CONFIRM_FLATPAK" =~ ^[Nn]$ ]]; then
        flatpak uninstall -y "$FLATPAK_ID"
        if [ $? -eq 0 ]; then
            echo -e "\e[1;32m[✓] Flatpak uninstalled successfully.\e[0m"
            if [ -d "$HOME/.var/app/$FLATPAK_ID" ]; then
                read -p "Delete leftover Flatpak data in ~/.var/app/$FLATPAK_ID? [y/N]: " DELDATA
                if [[ "$DELDATA" =~ ^[Yy]$ ]]; then
                    rm -rf "$HOME/.var/app/$FLATPAK_ID"
                    echo -e "\e[1;32m[✓] Deleted Flatpak user data.\e[0m"
                fi
            fi
        fi
        # Remove any leftover desktop file
        [ -n "$DESKTOP_FILE" ] && [ -f "$DESKTOP_FILE" ] && rm -f "$DESKTOP_FILE"
    fi
    # Proceed to clean launcher state and exit
    CLEANUP_NAME="${APP_NAME:-$FLATPAK_ID}"
    clean_launcher_state "$CLEANUP_NAME"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo -e "\n\e[1;32mUninstallation Finished!\e[0m"
    read -p "Press Enter to exit..."
    exit 0
fi

# Edge Case 4: Package Manager (Pacman / Yay / AUR)
PKG_NAME=""

# Query ownership of the .desktop file itself (if in system path)
if [ -n "$DESKTOP_FILE" ] && [[ "$DESKTOP_FILE" != "$HOME"* ]]; then
    PKG_INFO=$(pacman -Qo "$DESKTOP_FILE" 2>/dev/null)
    [ $? -eq 0 ] && PKG_NAME=$(echo "$PKG_INFO" | awk '{print $5}')
fi

# Query ownership of the binary (if binary exists and in system path)
if [ -z "$PKG_NAME" ] && [ "$BIN_EXISTS" -eq 1 ] && [[ "$BIN_PATH" != "$HOME"* ]]; then
    PKG_INFO=$(pacman -Qo "$BIN_PATH" 2>/dev/null)
    [ $? -eq 0 ] && PKG_NAME=$(echo "$PKG_INFO" | awk '{print $5}')
fi

# Fallback 1: Query pacman directly by binary basename
if [ -z "$PKG_NAME" ] && [ -n "$CMD_BASENAME" ]; then
    if pacman -Q "$CMD_BASENAME" >/dev/null 2>&1; then
        PKG_NAME="$CMD_BASENAME"
    fi
fi

# Fallback 2: Query pacman directly by desktop ID
if [ -z "$PKG_NAME" ] && [ -n "$DESKTOP_ID" ]; then
    BASE_DID="${DESKTOP_ID%.desktop}"
    if pacman -Q "$BASE_DID" >/dev/null 2>&1; then
        PKG_NAME="$BASE_DID"
    fi
fi

# Fallback 3: Query pacman directly by cleaned app name
if [ -z "$PKG_NAME" ] && [ -n "$APP_NAME" ]; then
    LOWER_APP=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -d '-')
    if pacman -Q "$LOWER_APP" >/dev/null 2>&1; then
        PKG_NAME="$LOWER_APP"
    fi
fi

# Core system packages safety guard
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
    read -p "Uninstall package '$PKG_NAME' with dependencies? [Y/n]: " CONFIRM_PKG
    if [[ ! "$CONFIRM_PKG" =~ ^[Nn]$ ]]; then
        if command -v yay >/dev/null 2>&1; then
            echo -e "\e[1;33mExecuting: yay -Rns $PKG_NAME\e[0m"
            yay -Rns "$PKG_NAME"
        else
            echo -e "\e[1;33mExecuting: sudo pacman -Rns $PKG_NAME\e[0m"
            sudo pacman -Rns "$PKG_NAME"
        fi

        if [ $? -eq 0 ]; then
            echo -e "\e[1;32m[✓] Package $PKG_NAME uninstalled successfully.\e[0m"
            # Crucial: Check and clean any user-local desktop entry override
            if [ -n "$DESKTOP_FILE" ] && [ -f "$DESKTOP_FILE" ] && [[ "$DESKTOP_FILE" == "$HOME"* ]]; then
                echo -e "Removing leftover user desktop entry: $DESKTOP_FILE"
                rm -f "$DESKTOP_FILE"
            fi
            # Also remove any ~/.local/share/applications matching PKG_NAME or CMD_BASENAME
            [ -n "$PKG_NAME" ] && rm -f "$HOME/.local/share/applications/${PKG_NAME}.desktop" 2>/dev/null
            [ -n "$CMD_BASENAME" ] && rm -f "$HOME/.local/share/applications/${CMD_BASENAME}.desktop" 2>/dev/null
        else
            echo -e "\n\e[1;31mPackage manager returned an error.\e[0m"
            read -p "Press Enter to exit..."
            exit 1
        fi
    else
        echo "Uninstallation cancelled."
        read -p "Press Enter to exit..."
        exit 0
    fi

elif [ "$BIN_EXISTS" -eq 0 ] && [ -n "$DESKTOP_FILE" ]; then
    # Edge Case 5: Orphaned / Dangling Desktop Entry (Binary missing, no package)
    echo -e "Type: \e[1;33mOrphaned Application Shortcut (Executable missing)\e[0m\n"
    echo -e "The executable binary is not present on your system."
    echo -e "This is an orphaned or leftover shortcut.\n"
    read -p "Remove this orphaned shortcut ($DESKTOP_FILE)? [Y/n]: " DELDESK
    if [[ ! "$DELDESK" =~ ^[Nn]$ ]]; then
        if [[ "$DESKTOP_FILE" == "$HOME"* ]]; then
            rm -f "$DESKTOP_FILE"
            echo -e "\e[1;32m[✓] Deleted desktop entry: $DESKTOP_FILE\e[0m"
        else
            sudo rm -f "$DESKTOP_FILE"
            echo -e "\e[1;32m[✓] Deleted system desktop entry with sudo.\e[0m"
        fi
    else
        echo "Preserved desktop entry."
    fi

else
    # Edge Case 6: Unmanaged Local or System Binary / AppImage
    echo -e "Type: \e[1;34mUnmanaged Executable / Local Application\e[0m\n"

    if [ "$BIN_EXISTS" -eq 1 ] && [ -n "$BIN_PATH" ]; then
        if [[ "$BIN_PATH" == "$HOME"* ]]; then
            read -p "Delete user binary file ($BIN_PATH)? [y/N]: " DELBIN
            if [[ "$DELBIN" =~ ^[Yy]$ ]]; then
                rm -f "$BIN_PATH"
                echo -e "\e[1;32m[✓] Deleted $BIN_PATH.\e[0m"
            fi
        elif [[ "$BIN_PATH" == "/usr/"* ]] || [[ "$BIN_PATH" == "/opt/"* ]]; then
            read -p "Delete system binary ($BIN_PATH) with sudo? [y/N]: " DELBIN
            if [[ "$DELBIN" =~ ^[Yy]$ ]]; then
                sudo rm -rf "$BIN_PATH"
                echo -e "\e[1;32m[✓] Deleted $BIN_PATH.\e[0m"
            fi
        fi
    fi

    # Cleanup desktop file
    if [ -n "$DESKTOP_FILE" ] && [ -f "$DESKTOP_FILE" ]; then
        if [[ "$DESKTOP_FILE" == "$HOME"* ]]; then
            read -p "Delete user desktop entry ($DESKTOP_FILE)? [Y/n]: " DELDESK
            if [[ ! "$DELDESK" =~ ^[Nn]$ ]]; then
                rm -f "$DESKTOP_FILE"
                echo -e "\e[1;32m[✓] Deleted desktop entry.\e[0m"
            fi
        else
            read -p "Delete system desktop entry ($DESKTOP_FILE) with sudo? [y/N]: " DELDESK
            if [[ "$DELDESK" =~ ^[Yy]$ ]]; then
                sudo rm -f "$DESKTOP_FILE"
                echo -e "\e[1;32m[✓] Deleted system desktop entry.\e[0m"
            fi
        fi
    fi
fi

# Function to cleanly remove an application from Quickshell state JSON files
clean_state_json() {
    local json_file="$1"
    local name_to_remove="$2"
    [ ! -f "$json_file" ] && return
    [ -z "$name_to_remove" ] && return

    if command -v jq >/dev/null 2>&1; then
        local filtered
        filtered=$(jq --arg n "$name_to_remove" 'map(select((. | ascii_downcase) != ($n | ascii_downcase)))' "$json_file" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$filtered" ] && [ "$filtered" != "null" ]; then
            echo "$filtered" > "$json_file"
        fi
    fi
}

# Clean from Quickshell recent and pinned apps
APP_NAMES_TO_CLEAN=()
[ -n "$APP_NAME" ] && APP_NAMES_TO_CLEAN+=("$APP_NAME")
[ -n "$CMD_BASENAME" ] && APP_NAMES_TO_CLEAN+=("$CMD_BASENAME")
[ -n "$DESKTOP_ID" ] && APP_NAMES_TO_CLEAN+=("${DESKTOP_ID%.desktop}")
[ -n "$PKG_NAME" ] && APP_NAMES_TO_CLEAN+=("$PKG_NAME")

STATE_FILES=(
    "$HOME/.config/quickshell/state/recent_apps.json"
    "$HOME/.config/quickshell/state/pinned_apps.json"
    "$HOME/code/arch-theme/quickshell/state/recent_apps.json"
    "$HOME/code/arch-theme/quickshell/state/pinned_apps.json"
)

for sf in "${STATE_FILES[@]}"; do
    for an in "${APP_NAMES_TO_CLEAN[@]}"; do
        clean_state_json "$sf" "$an"
    done
done

# Edge Case 7: Deep Config & Cache Cleanup (XDG Standard)
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
                        bname=$(basename "$match")
                        # Exclude root system config dirs or standard shell folders
                        if [ "$bname" != "hypr" ] && [ "$bname" != "quickshell" ] && [ "$bname" != "kitty" ] && [ "$bname" != "applications" ] && [ "$bname" != "icons" ]; then
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
            size_str=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
            echo -e "\e[1;31m  - $dir\e[0m \e[1;30m(${size_str:-?})\e[0m"
        done

        read -p "Delete all the above application data directories? [y/N]: " DELCONF
        if [[ "$DELCONF" =~ ^[Yy]$ ]]; then
            for dir in "${UNIQUE_DIRS[@]}"; do
                rm -rf "$dir"
            done
            echo -e "\e[1;32m[✓] Successfully cleaned application data.\e[0m"
        else
            echo "Preserved application data directories."
        fi
    fi
fi

# Refresh XDG desktop database so launcher and system update immediately
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true
touch "$HOME/.local/share/applications" 2>/dev/null || true

echo -e "\n\e[1;32mUninstallation Finished!\e[0m"
read -p "Press Enter to exit..."
