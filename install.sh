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

# --- Pre-flight Checks ---
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root. Use your normal user account."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "Welcome to the Antigravity Arch Dotfiles Installer!"
sleep 1

# --- 1. Install AUR Helper (yay) ---
if ! command -v yay &> /dev/null; then
    log_info "yay not found. Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    makepkg -si --noconfirm
    rm -rf /tmp/yay-bin
    cd "$DOTFILES_DIR"
    log_success "yay installed!"
else
    log_success "yay is already installed."
fi

# --- 2. Install Packages ---
log_info "Installing dependencies..."
PACKAGES=(
    # Core Environment
    "sway" "swaybg" "waybar" "rofi-wayland" "kitty" "thunar"
    # System/UX Utilities
    "swayidle" "swaylock" "brightnessctl" "swaync" "polkit-kde-agent" "network-manager-applet"
    # Clipboard
    "wl-clipboard" "cliphist"
    # Default Apps
    "zen-browser-bin" "zed" "neovim" "zathura" "zathura-pdf-mupdf" "imv" "mpv" "xarchiver" "vesktop"
    # Theming & Fonts
    "adw-gtk3" "ttf-jetbrains-mono-nerd" "librsvg" "npm"
)
yay -S --needed --noconfirm "${PACKAGES[@]}"
log_success "Dependencies installed!"

# --- 3. Install Zinit ---
if [ ! -d "$HOME/.local/share/zinit" ]; then
    log_info "Installing Zinit plugin manager..."
    bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
    log_success "Zinit installed!"
fi

# --- 4. Directory Management ---
log_info "Creating required directories..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/Pictures/wallpapers"
log_success "Directories created!"

# --- 5. Symlinking Configurations ---
log_info "Backing up and symlinking configs..."

backup_and_symlink() {
    local SRC="$1"
    local DEST="$2"
    
    if [ -e "$DEST" ] || [ -L "$DEST" ]; then
        if [ ! -L "$DEST" ]; then
            log_info "Backing up existing $DEST to ${DEST}.bak"
            mv "$DEST" "${DEST}.bak"
        else
            rm "$DEST"
        fi
    fi
    ln -sf "$SRC" "$DEST"
}

# Config directories
for config in sway waybar kitty rofi swaync gtk-3.0 gtk-4.0; do
    backup_and_symlink "$DOTFILES_DIR/$config" "$HOME/.config/$config"
done

# Independent dotfiles
backup_and_symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
backup_and_symlink "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
backup_and_symlink "$DOTFILES_DIR/mimeapps.list" "$HOME/.config/mimeapps.list"
log_success "Configs successfully linked!"

# --- 6. Install Wallpaper ---
log_info "Installing wallpaper..."
cp "$DOTFILES_DIR/wallpapers/satisfaction_waybar_blur.png" "$HOME/Pictures/wallpapers/satisfaction_waybar_blur.png"
log_success "Wallpaper installed!"

# --- 7. Custom Icons & Desktop Launchers ---
log_info "Symlinking custom icons and desktop files..."
backup_and_symlink "$DOTFILES_DIR/icons/YAMIS-enlarged" "$HOME/.local/share/icons/YAMIS-enlarged"
backup_and_symlink "$DOTFILES_DIR/applications/antigravity.desktop" "$HOME/.local/share/applications/antigravity.desktop"
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/YAMIS-enlarged" || true
log_success "Custom icons linked!"

# --- 8. Patch Scripts ---
log_info "Installing patch scripts..."
sudo cp "$DOTFILES_DIR/scripts/install-antigravity-tray-patch.sh" "/usr/local/bin/install-antigravity-tray-patch.sh"
sudo chmod +x "/usr/local/bin/install-antigravity-tray-patch.sh"
log_success "Patch scripts installed!"

# --- 9. Systemd Services ---
log_info "Enabling systemd user services..."
backup_and_symlink "$DOTFILES_DIR/systemd/user/sway-hw-notify.service" "$HOME/.config/systemd/user/sway-hw-notify.service"
systemctl --user daemon-reload
systemctl --user enable --now sway-hw-notify.service
log_success "Systemd services enabled!"

log_success "Installation Complete! Reboot or log out to enjoy your pristine Sway setup!"
