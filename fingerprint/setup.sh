#!/bin/bash
# ============================================================================
# Fingerprint Setup for ThinkPad T480 (Synaptics Prometheus 06cb:009a)
# ============================================================================
# This script installs the open-source fingerprint driver stack for
# ThinkPads with the Synaptics Metallica/Prometheus sensor.
#
# Driver Stack:
#   python-validity  →  Hardware USB driver (talks to the sensor chip)
#   open-fprintd     →  D-Bus daemon (replaces the standard fprintd)
#   fprintd-clients  →  CLI tools (fprintd-enroll, fprintd-verify, etc.)
#   pam-fprint-grosshack  →  PAM module for simultaneous password+fingerprint (used for sudo/swaylock; excluded from Lemurs login)
#
# NOTE: This script must be run AFTER install.sh (needs yay).
# ============================================================================

set -e

GREEN="\e[32m"
BLUE="\e[34m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log_info()    { echo -e "${BLUE}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }
log_warn()    { echo -e "${YELLOW}[!] $1${RESET}"; }
log_error()   { echo -e "${RED}[!] $1${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Pre-flight ---
if [ "$EUID" -eq 0 ]; then
    log_error "Do not run as root. Use your normal user account."
    exit 1
fi

if ! command -v yay &> /dev/null; then
    log_error "yay is required. Run install.sh first."
    exit 1
fi

# Check if this is a ThinkPad with the correct sensor
if ! lsusb 2>/dev/null | grep -qi "06cb:009a\|06cb:00bd\|Synaptics"; then
    log_warn "No compatible Synaptics fingerprint sensor detected (06cb:009a)."
    log_warn "This script is designed for ThinkPad T480/T480s/X1C6 with Validity sensors."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# ============================================================================
# PHASE 1: Install Packages
# ============================================================================
log_info "Installing fingerprint driver stack (AUR)..."

FPRINT_PACKAGES=(
    "python-validity"           # USB driver for Synaptics Prometheus
    "open-fprintd"              # D-Bus daemon (fprintd replacement)
    "fprintd-clients-git"       # CLI tools (enroll, verify, list)
)

yay -S --needed --noconfirm "${FPRINT_PACKAGES[@]}"

log_info "Compiling pam-fprint-grosshack from source..."
# pam-fprint-grosshack depends on fprintd by default, which conflicts with open-fprintd
# We need to manually download it, remove the dependency, and compile it
if ! pacman -Qs pam-fprint-grosshack > /dev/null; then
    cd /tmp
    rm -rf pam-fprint-grosshack
    git clone https://aur.archlinux.org/pam-fprint-grosshack.git
    cd pam-fprint-grosshack
    sed -i "s/'fprintd' //" PKGBUILD
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
else
    log_success "pam-fprint-grosshack is already installed."
fi
log_success "Fingerprint packages installed!"

# ============================================================================
# PHASE 2: Firmware Extraction
# ============================================================================
log_info "Extracting proprietary firmware from Windows driver package..."
log_info "(This downloads a .cab file and extracts certificates/firmware)"
sudo validity-sensors-firmware
log_success "Firmware extracted!"

# ============================================================================
# PHASE 3: Sensor Initialization
# ============================================================================
log_info "Initializing fingerprint sensor..."

# Stop driver if running (to release USB device)
sudo systemctl stop python3-validity 2>/dev/null || true

# Factory reset the sensor to clear any stale state
log_info "Factory resetting sensor (clears old enrollments from hardware)..."
sudo python3 /usr/share/python-validity/playground/factory-reset.py || {
    log_warn "Factory reset failed. If you see 'Resource busy', try:"
    log_warn "  1. Fully shut down (not restart) your laptop"
    log_warn "  2. Wait 10 seconds"
    log_warn "  3. Boot back up and run this script again"
}

# ============================================================================
# PHASE 4: Enable Services
# ============================================================================
log_info "Enabling systemd services..."

sudo systemctl enable --now python3-validity.service
sudo systemctl enable open-fprintd-resume.service
sudo systemctl enable open-fprintd-suspend.service
sudo systemctl enable python3-validity-suspend-hotfix.service

log_info "Installing swaylock resume hook..."
sudo cp "$SCRIPT_DIR/swaylock-fprint-resume.sh" /usr/lib/systemd/system-sleep/swaylock-fprint-resume.sh
sudo chmod +x /usr/lib/systemd/system-sleep/swaylock-fprint-resume.sh

log_success "Services enabled!"

# ============================================================================
# PHASE 5: PAM Configuration (fingerprint for sudo + swaylock)
# ============================================================================
log_info "Configuring PAM for fingerprint authentication..."

# sudo: fingerprint as sufficient (try fingerprint first, fall back to password)
sudo cp "$SCRIPT_DIR/pam/sudo" /etc/pam.d/sudo
sudo chmod 644 /etc/pam.d/sudo

# swaylock: fingerprint as sufficient (unlock screen with fingerprint)
sudo cp "$SCRIPT_DIR/pam/swaylock" /etc/pam.d/swaylock
sudo chmod 644 /etc/pam.d/swaylock

log_success "PAM configured! Fingerprint works for sudo and swaylock."

# ============================================================================
# PHASE 6: Enroll Fingerprints
# ============================================================================
echo ""
log_info "Time to enroll your fingerprints!"
log_info "You'll be asked to touch the sensor multiple times for each finger."
echo ""

# Wait for services to stabilize
sleep 2

for finger in right-index-finger right-thumb left-index-finger; do
    echo ""
    log_info "Enrolling: $finger"
    log_info "Touch the sensor repeatedly when prompted..."
    fprintd-enroll -f "$finger" || {
        log_warn "Failed to enroll $finger. You can retry later with:"
        log_warn "  fprintd-enroll -f $finger"
    }
done

echo ""
log_success "Fingerprint setup complete!"
echo ""
log_info "Enrolled fingers:"
fprintd-list "$(whoami)" 2>/dev/null || true
echo ""
log_info "Test it out:"
log_info "  • sudo ls        (should prompt for fingerprint)"
log_info "  • swaylock       (touch sensor to unlock)"
log_info "  • fprintd-verify (quick hardware test)"
echo ""
log_warn "If fingerprint stops working after suspend/resume:"
log_warn "  sudo systemctl restart python3-validity open-fprintd"
