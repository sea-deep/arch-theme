# Fingerprint Setup for ThinkPad T480 (Synaptics Prometheus)

## Overview

This sets up the open-source fingerprint driver stack for ThinkPads with the
Synaptics Metallica/Prometheus sensor (`06cb:009a`).

Fingerprint auth is enabled for:
- **sudo** — touch sensor instead of typing password
- **hyprlock** — touch sensor to unlock screen
- **polkit** — system auth prompts

Fingerprint is intentionally **NOT** used for the boot greeter (ly)
because the sensor requires a warm-up period after cold boot.

## Driver Stack

| Package | Role |
|---------|------|
| `python-validity` | USB driver that talks to the sensor hardware |
| `open-fprintd` | D-Bus daemon (replacement for standard fprintd) |
| `fprintd-clients-git` | CLI tools (enroll, verify, list) |
| `pam-fprint-grosshack` | PAM module for simultaneous fingerprint + password |

## Systemd Services

| Service | Purpose |
|---------|---------|
| `python3-validity.service` | Main sensor driver daemon |
| `open-fprintd-resume.service` | Reinitialize sensor after suspend/resume |
| `open-fprintd-suspend.service` | Clean shutdown before suspend |
| `python3-validity-suspend-hotfix.service` | Restart driver after hibernate |

## Usage

### Fresh Install
```bash
chmod +x fingerprint/setup.sh
./fingerprint/setup.sh
```

### Re-enroll a finger
```bash
fprintd-enroll -f right-index-finger
```

### Test fingerprint
```bash
fprintd-verify
```

### Troubleshooting

**Sensor not responding after suspend:**
```bash
sudo systemctl restart python3-validity open-fprintd
```

**Factory reset sensor (nuclear option):**
```bash
sudo systemctl stop python3-validity
sudo python3 /usr/share/python-validity/playground/factory-reset.py
sudo systemctl start python3-validity open-fprintd
```

**Sensor locked (Resource busy / Operation timed out):**
1. Fully shut down (not restart) the laptop
2. Wait 10 seconds
3. Boot back up
4. Run `sudo validity-sensors-firmware` then factory reset
