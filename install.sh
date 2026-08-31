#!/bin/bash

set -e

# --- Colors ---
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

log_info() { echo -e "${BLUE}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }
log_warn() { echo -e "${YELLOW}[!] $1${RESET}"; }
log_error() { echo -e "${RED}[!] $1${RESET}"; }

prompt_yn() {
    while true; do
        read -p "$(echo -e "${BLUE}[?] $1 [Y/n] ${RESET}")" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) return 0;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# --- Pre-flight Checks ---
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root. Use your normal user account."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "Welcome to the Miku Arch Dotfiles & Quickshell Installer!"
sleep 1

# --- 1. Pacman Configurations & Repositories ---
log_info "Configuring Pacman parallel downloads and repositories..."

# Enable Parallel Downloads if not already enabled
if grep -q "^#ParallelDownloads" /etc/pacman.conf; then
    log_info "Enabling Parallel Downloads..."
    sudo sed -i "s/^#ParallelDownloads/ParallelDownloads/" /etc/pacman.conf
fi

# Enable multilib repo if not already enabled
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    log_info "Enabling multilib repository..."
    sudo sed -i "/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//" /etc/pacman.conf
fi

# Enable Chaotic AUR if not already enabled
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    log_info "Setting up Chaotic AUR..."
    # 1. Receive key with multiple keyserver fallbacks
    sudo pacman-key --recv-key 3056513E7043D7A13B266D9614E7517E4F707477 --keyserver hkps://keyserver.ubuntu.com || \
    sudo pacman-key --recv-key 3056513E7043D7A13B266D9614E7517E4F707477 --keyserver keys.openpgp.org || \
    sudo pacman-key --recv-key 3056513E7043D7A13B266D9614E7517E4F707477 --keyserver pgp.mit.edu || true
    sudo pacman-key --lsign-key 3056513E7043D7A13B266D9614E7517E4F707477 || true
    # 2. Install keyring and mirrorlist
    sudo pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" || true
    sudo pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst" || true
    # 3. Append to pacman.conf
    sudo bash -c "cat <<EOF >> /etc/pacman.conf

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF"
    sudo pacman -Sy
    log_success "Chaotic AUR enabled!"
fi

# --- 2. Install AUR Helper (yay) ---
if ! command -v yay &> /dev/null; then
    log_info "yay not found. Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    TMP_YAY_DIR=$(mktemp -d -t yay-bin-XXXXXX)
    git clone https://aur.archlinux.org/yay-bin.git "$TMP_YAY_DIR"
    cd "$TMP_YAY_DIR"
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf "$TMP_YAY_DIR"
    log_success "yay installed!"
else
    log_success "yay is already installed."
fi

# --- 3. Install Packages ---
log_info "Installing core packages and Quickshell dependencies..."
PACKAGES=(
    # Desktop Shell & Compositor
    "hyprland" "quickshell" "kitty" "thunar" "ly"
    # Qt6 / Quickshell Runtime Dependencies
    "qt6-declarative" "qt6-wayland" "qt6-svg" "qt6-5compat" "qt6-shadertools" "librsvg"
    # Sway fallback & background daemons
    "swayfx" "swaybg" "swww"
    # System / UX Utilities
    "hypridle" "hyprlock" "swayidle" "swaylock" "brightnessctl" "swaync" "wlogout" 
    "polkit-kde-agent" "network-manager-applet" "xdg-desktop-portal" "xdg-desktop-portal-hyprland" "xdg-desktop-portal-wlr" 
    "jq" "socat" "upower" "playerctl" "pamixer" "pipewire" "wireplumber"
    # Screenshot & Recording
    "grim" "slurp" "swappy" "wf-recorder" "ffmpeg"
    # Clipboard & History
    "wl-clipboard" "cliphist" "clipse"
    # Terminal Tools & Showcase
    "pipes.sh" "fastfetch" "ddgr" "neovim" "mpv" "imv" "xarchiver" "snapshot"
    # Default Apps
    "zen-browser-bin" "zed" "zathura" "zathura-pdf-mupdf" "vesktop"
    # Theming, Fonts & Icons
    "adw-gtk-theme" "ttf-ibm-plex" "ttf-firacode-nerd" "noto-fonts-emoji" "npm" "kvantum" "kvantum-qt5"
)

yay -S --needed --noconfirm "${PACKAGES[@]}" || {
    log_warn "Some packages failed to install in batch, attempting fallback install for critical tools..."
    yay -S --needed --noconfirm hyprland quickshell qt6-declarative qt6-wayland swappy wf-recorder cliphist wl-clipboard ttf-firacode-nerd || true
}
log_success "Dependencies installed!"

# --- 4. Install Zinit ---
if [ ! -d "$HOME/.local/share/zinit" ]; then
    if prompt_yn "Install Zinit plugin manager (Recommended for ZSH)?"; then
        log_info "Installing Zinit plugin manager..."
        bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" || true
        log_success "Zinit installed!"
    else
        log_info "Skipping Zinit..."
    fi
fi

# --- 5. Directory Management ---
log_info "Creating required user directories..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/share/cliphist"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/Pictures/wallpapers"
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Videos/Recordings"
mkdir -p "$HOME/code"
log_success "Directories created!"

# --- 6. Set Executable Permissions on All Scripts ---
log_info "Ensuring execution permissions on helper scripts..."
find "$DOTFILES_DIR/hypr" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$DOTFILES_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
[ -f "$DOTFILES_DIR/ly/set-tty-theme.sh" ] && chmod +x "$DOTFILES_DIR/ly/set-tty-theme.sh"
log_success "Script permissions configured!"

# --- 7. Symlinking Configurations ---
log_info "Backing up and symlinking configs..."

backup_and_symlink() {
    local SRC="$1"
    local DEST="$2"
    
    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        if [ ! -L "$DEST" ]; then
            local BAK="${DEST}.bak"
            if [ -e "$BAK" ]; then
                BAK="${DEST}_$(date +%Y%m%d_%H%M%S).bak"
            fi
            log_info "Backing up existing $DEST to $BAK"
            mv "$DEST" "$BAK"
        else
            rm -f "$DEST"
        fi
    fi
    ln -sf "$SRC" "$DEST"
}

# Config directories
CONFIG_DIRS=(
    "hypr" "quickshell" "kitty" "sway" "swaylock" "waybar" "swaync" "wlogout" 
    "btop" "environment.d" "qt5ct" "qt6ct" "tlpui" "gtk-3.0" "gtk-4.0" 
    "fontconfig" "Thunar" "xfce4" "Kvantum" "fastfetch" "rofi"
)

for config in "${CONFIG_DIRS[@]}"; do
    if [ -d "$DOTFILES_DIR/$config" ]; then
        backup_and_symlink "$DOTFILES_DIR/$config" "$HOME/.config/$config"
    fi
done

# Independent dotfiles
[ -f "$DOTFILES_DIR/starship.toml" ] && backup_and_symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
[ -f "$DOTFILES_DIR/zshrc" ] && backup_and_symlink "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
[ -f "$DOTFILES_DIR/mimeapps.list" ] && backup_and_symlink "$DOTFILES_DIR/mimeapps.list" "$HOME/.config/mimeapps.list"
log_success "Configs successfully linked!"

# --- 8. Install Wallpaper & Generate Bookmarks ---
log_info "Installing wallpapers..."
if [ -d "$DOTFILES_DIR/wallpapers" ]; then
    cp -r "$DOTFILES_DIR/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
fi
log_success "Wallpapers installed!"

log_info "Generating file manager bookmarks..."
cat << EOF > "$DOTFILES_DIR/gtk-3.0/bookmarks"
file://$HOME/Pictures
file://$HOME/code
file://$HOME/Music
file://$HOME/Documents
file://$HOME/Videos
file://$HOME/Downloads
EOF

# --- 9. Custom Icons & Desktop Launchers ---
log_info "Symlinking custom icons and desktop files..."
if [ -d "$DOTFILES_DIR/icons/YAMIS-enlarged" ]; then
    backup_and_symlink "$DOTFILES_DIR/icons/YAMIS-enlarged" "$HOME/.local/share/icons/YAMIS-enlarged"
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/YAMIS-enlarged" 2>/dev/null || true
fi
if [ -f "$DOTFILES_DIR/applications/miku.desktop" ]; then
    backup_and_symlink "$DOTFILES_DIR/applications/miku.desktop" "$HOME/.local/share/applications/miku.desktop"
fi
log_success "Custom icons linked!"

# --- 10. System Configurations & Display Manager ---
if prompt_yn "Install Miku Tray Icon Patch (Specific to Miku theme)?"; then
    log_info "Installing system configurations and patch scripts..."
    if [ -f "$DOTFILES_DIR/scripts/install-miku-tray-patch.sh" ]; then
        sudo cp "$DOTFILES_DIR/scripts/install-miku-tray-patch.sh" "/usr/local/bin/install-miku-tray-patch.sh"
        sudo chmod +x "/usr/local/bin/install-miku-tray-patch.sh"
        log_success "Tray patch installed!"
    fi
fi

if prompt_yn "Restore TLP Power Management Configuration?"; then
    log_info "Restoring TLP power management system config..."
    if [ -f "$DOTFILES_DIR/etc/tlp.conf" ]; then
        sudo cp "$DOTFILES_DIR/etc/tlp.conf" "/etc/tlp.conf"
        sudo chmod 644 "/etc/tlp.conf"
    fi
    if [ -f "$DOTFILES_DIR/etc/polkit-1/rules.d/50-tlp.rules" ]; then
        sudo mkdir -p "/etc/polkit-1/rules.d"
        sudo cp "$DOTFILES_DIR/etc/polkit-1/rules.d/50-tlp.rules" "/etc/polkit-1/rules.d/50-tlp.rules"
        sudo chmod 644 "/etc/polkit-1/rules.d/50-tlp.rules"
    fi
    if [ -f "$DOTFILES_DIR/etc/sudoers.d/tlp" ]; then
        sudo mkdir -p "/etc/sudoers.d"
        sudo cp "$DOTFILES_DIR/etc/sudoers.d/tlp" "/etc/sudoers.d/tlp"
        sudo chmod 440 "/etc/sudoers.d/tlp"
    fi
    log_success "TLP configuration and passwordless execution rules restored!"
fi

if prompt_yn "Setup Fingerprint Authentication?"; then
    log_info "Running fingerprint setup..."
    if [ -f "$DOTFILES_DIR/fingerprint/setup.sh" ]; then
        sudo bash "$DOTFILES_DIR/fingerprint/setup.sh"
        log_success "Fingerprint setup completed!"
    else
        log_warn "Fingerprint setup script not found!"
    fi
fi

if prompt_yn "Configure Ly Display Manager & TTY theme?"; then
    log_info "Setting up Ly display manager..."
    sudo mkdir -p /etc/ly

    # Config symlink
    if [ -f "$DOTFILES_DIR/ly/config.ini" ]; then
        sudo ln -sf "$DOTFILES_DIR/ly/config.ini" /etc/ly/config.ini
    fi

    # PAM config
    if [ -f "$DOTFILES_DIR/ly/pam" ]; then
        sudo cp "$DOTFILES_DIR/ly/pam" /etc/pam.d/ly
        sudo chmod 644 /etc/pam.d/ly
    fi

    # TTY color theme script and systemd service
    if [ -f "$DOTFILES_DIR/ly/set-tty-theme.sh" ]; then
        sudo cp "$DOTFILES_DIR/ly/set-tty-theme.sh" /etc/ly/set-tty-theme.sh
        sudo chmod +x /etc/ly/set-tty-theme.sh
    fi
    if [ -f "$DOTFILES_DIR/ly/tty-theme.service" ]; then
        sudo cp "$DOTFILES_DIR/ly/tty-theme.service" /etc/systemd/system/tty-theme.service
        sudo chmod 644 /etc/systemd/system/tty-theme.service
    fi

    # Fix swaylock PAM to remove faillock delay
    if [ -f "$DOTFILES_DIR/swaylock/pam" ]; then
        sudo cp "$DOTFILES_DIR/swaylock/pam" /etc/pam.d/swaylock
        sudo chmod 644 /etc/pam.d/swaylock
    fi

    # Disable old display managers
    sudo systemctl disable lemurs.service 2>/dev/null || true
    sudo systemctl disable greetd.service 2>/dev/null || true
    sudo systemctl disable getty@tty2.service 2>/dev/null || true

    # Enable Ly and TTY color theme
    sudo systemctl enable -f ly@tty2.service 2>/dev/null || true
    sudo systemctl enable tty-theme.service 2>/dev/null || true
    sudo systemctl daemon-reload
    log_success "Ly display manager configured!"
fi

# --- 11. Systemd User Services ---
log_info "Enabling systemd user services..."
if [ -f "$DOTFILES_DIR/systemd/user/sway-hw-notify.service" ]; then
    backup_and_symlink "$DOTFILES_DIR/systemd/user/sway-hw-notify.service" "$HOME/.config/systemd/user/sway-hw-notify.service"
    systemctl --user daemon-reload
    systemctl --user enable --now sway-hw-notify.service 2>/dev/null || true
fi
log_success "Systemd services enabled!"

log_success "Installation Complete! Reboot or log out to enjoy your pristine Hyprland + Quickshell setup!"
