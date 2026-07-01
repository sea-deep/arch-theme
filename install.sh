#!/bin/bash

set -e

# --- Colors ---
GREEN="\e[32m"
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

log_info() { echo -e "${BLUE}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }
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

log_info "Welcome to the Miku Arch Dotfiles Installer!"
sleep 1

# --- 1. Pacman Configurations & Repositories ---
log_info "Configuring Pacman parallel downloads and repositories..."

# Enable Parallel Downloads if not already enabled
if grep -q "^#ParallelDownloads" /etc/pacman.conf; then
    log_info "Enabling Parallel Downloads..."
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
fi

# Enable multilib repo if not already enabled
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    log_info "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
fi

# Enable Chaotic AUR if not already enabled
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    log_info "Setting up Chaotic AUR..."
    # 1. Receive key
    sudo pacman-key --recv-key 3056513E7043D7A13B266D9614E7517E4F707477 --keyserver keyserver.ubuntu.com || true
    sudo pacman-key --lsign-key 3056513E7043D7A13B266D9614E7517E4F707477 || true
    # 2. Install keyring and mirrorlist
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' || true
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || true
    # 3. Append to pacman.conf
    sudo bash -c 'cat <<EOF >> /etc/pacman.conf

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF'
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
log_info "Installing dependencies..."
PACKAGES=(
    # Core Environment
    "swayfx" "swaybg" "waybar" "rofi-wayland" "kitty" "thunar"
    # Display Manager
    "lemurs"
    # System/UX Utilities
    "swayidle" "swaylock" "brightnessctl" "swaync" "wlogout" "polkit-kde-agent" "network-manager-applet" "sway-audio-idle-inhibit-git" "xdg-desktop-portal" "xdg-desktop-portal-wlr" "jq"
    # Showcase & Terminal Tools
    "wf-recorder" "pipes.sh" "fastfetch"
    # Clipboard
    "wl-clipboard" "cliphist"
    # Default Apps
    "zen-browser-bin" "zed" "neovim" "zathura" "zathura-pdf-mupdf" "imv" "mpv" "xarchiver" "vesktop" "snapshot"
    # Theming & Fonts
    "adw-gtk-theme" "ttf-ibm-plex" "ttf-firacode-nerd" "librsvg" "npm" "kvantum" "kvantum-qt5"
)
yay -S --needed --noconfirm "${PACKAGES[@]}"
log_success "Dependencies installed!"

# --- 4. Install Zinit ---
if [ ! -d "$HOME/.local/share/zinit" ]; then
    if prompt_yn "Install Zinit plugin manager (Recommended for ZSH)?"; then
        log_info "Installing Zinit plugin manager..."
        bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
        log_success "Zinit installed!"
    else
        log_info "Skipping Zinit..."
    fi
fi

# --- 5. Directory Management ---
log_info "Creating required directories..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/Pictures/wallpapers"
log_success "Directories created!"

# --- 6. Symlinking Configurations ---
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
            rm "$DEST"
        fi
    fi
    ln -sf "$SRC" "$DEST"
}

# Config directories
for config in sway swaylock waybar kitty rofi swaync wlogout btop environment.d qt5ct qt6ct tlpui gtk-3.0 gtk-4.0 fontconfig Thunar xfce4 Kvantum fastfetch; do
    backup_and_symlink "$DOTFILES_DIR/$config" "$HOME/.config/$config"
done

# Independent dotfiles
backup_and_symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
backup_and_symlink "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
backup_and_symlink "$DOTFILES_DIR/mimeapps.list" "$HOME/.config/mimeapps.list"
log_success "Configs successfully linked!"

# --- 7. Install Wallpaper & Generate Bookmarks ---
log_info "Installing wallpapers..."
cp "$DOTFILES_DIR/wallpapers/satisfaction_waybar_blur.png" "$HOME/Pictures/wallpapers/satisfaction_waybar_blur.png"
cp "$DOTFILES_DIR/wallpapers/satisfaction_waybar_blur_lock.png" "$HOME/Pictures/wallpapers/satisfaction_waybar_blur_lock.png"
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

# --- 8. Custom Icons & Desktop Launchers ---
log_info "Symlinking custom icons and desktop files..."
backup_and_symlink "$DOTFILES_DIR/icons/YAMIS-enlarged" "$HOME/.local/share/icons/YAMIS-enlarged"
backup_and_symlink "$DOTFILES_DIR/applications/miku.desktop" "$HOME/.local/share/applications/miku.desktop"
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/YAMIS-enlarged" || true
log_success "Custom icons linked!"

# --- 9. System Configurations & Patch Scripts ---
if prompt_yn "Install Miku Tray Icon Patch (Specific to Miku theme)?"; then
    log_info "Installing system configurations and patch scripts..."
    sudo cp "$DOTFILES_DIR/scripts/install-miku-tray-patch.sh" "/usr/local/bin/install-miku-tray-patch.sh"
    sudo chmod +x "/usr/local/bin/install-miku-tray-patch.sh"
    log_success "Tray patch installed!"
fi

if prompt_yn "Restore TLP Power Management Configuration?"; then
    log_info "Restoring TLP power management system config..."
    if [ -f "$DOTFILES_DIR/etc/tlp.conf" ]; then
        sudo cp "$DOTFILES_DIR/etc/tlp.conf" "/etc/tlp.conf"
        sudo chmod 644 "/etc/tlp.conf"
        log_success "TLP restored!"
    fi
fi

if prompt_yn "Setup Fingerprint Authentication?"; then
    log_info "Running fingerprint setup..."
    if [ -f "$DOTFILES_DIR/fingerprint/setup.sh" ]; then
        sudo bash "$DOTFILES_DIR/fingerprint/setup.sh"
        log_success "Fingerprint setup completed!"
    else
        log_error "Fingerprint setup script not found!"
    fi
fi

log_info "Setting up Lemurs display manager..."
sudo mkdir -p /etc/lemurs
sudo mkdir -p /etc/lemurs/wayland

# Config (symlink so repo changes apply instantly)
sudo ln -sf "$DOTFILES_DIR/lemurs/config.toml" /etc/lemurs/config.toml

# PAM config (copy — symlinks in /etc/pam.d can cause issues)
sudo cp "$DOTFILES_DIR/lemurs/pam" /etc/pam.d/lemurs
sudo chmod 644 /etc/pam.d/lemurs

# Disable old display managers
sudo systemctl disable ly.service 2>/dev/null || true
sudo systemctl disable greetd.service 2>/dev/null || true

# Enable lemurs
sudo systemctl enable lemurs.service
sudo systemctl daemon-reload
log_success "System scripts and configs installed!"

# --- 10. Systemd Services ---
log_info "Enabling systemd user services..."
backup_and_symlink "$DOTFILES_DIR/systemd/user/sway-hw-notify.service" "$HOME/.config/systemd/user/sway-hw-notify.service"
systemctl --user daemon-reload
systemctl --user enable --now sway-hw-notify.service
log_success "Systemd services enabled!"

log_success "Installation Complete! Reboot or log out to enjoy your pristine Sway setup!"
