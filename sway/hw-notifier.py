#!/usr/bin/env python3
import subprocess
import time
import os
import glob

# Ensure DBus connection for notify-send
os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path=/run/user/{os.getuid()}/bus"

def notify(title, message, icon, sound):
    subprocess.Popen(["paplay", sound])
    subprocess.Popen(["notify-send", title, message, "-i", icon, "-a", "System"])

def get_ac_status():
    for path in glob.glob("/sys/class/power_supply/AC*/online"):
        try:
            with open(path, "r") as f:
                return f.read().strip()
        except Exception:
            pass
    return "unknown"

def get_device_name(current_event):
    vendor = current_event.get("ID_VENDOR_FROM_DATABASE", current_event.get("ID_VENDOR_ENC", current_event.get("ID_VENDOR", "")))
    model = current_event.get("ID_MODEL_FROM_DATABASE", current_event.get("ID_MODEL_ENC", current_event.get("ID_MODEL", "")))
    # Clean up udev escape sequences (like \x20 for space)
    vendor = vendor.replace(r'\x20', ' ')
    model = model.replace(r'\x20', ' ')
    name = f"{vendor} {model}".strip()
    return name if name else "Unknown USB Device"

def main():
    # Start udevadm monitor in environment mode for easy parsing
    process = subprocess.Popen(
        ["udevadm", "monitor", "--udev", "--subsystem-match=usb", "--subsystem-match=power_supply", "--environment"],
        stdout=subprocess.PIPE,
        universal_newlines=True,
        bufsize=1
    )

    last_usb_add = 0
    last_usb_remove = 0
    last_power_plug = 0
    last_power_unplug = 0

    current_event = {}
    device_names_cache = {}

    for line in process.stdout:
        line = line.strip()
        if not line:
            # Empty line means end of an event block
            if current_event.get("SUBSYSTEM") == "usb" and current_event.get("DEVTYPE") == "usb_device":
                action = current_event.get("ACTION")
                devpath = current_event.get("DEVPATH")
                now = time.time()
                
                if action in ["add", "bind"] and now - last_usb_add > 1:
                    last_usb_add = now
                    dev_name = get_device_name(current_event)
                    if devpath:
                        device_names_cache[devpath] = dev_name
                    notify("Hardware", f"{dev_name} Connected", "drive-removable-media", "/usr/share/sounds/Pop/stereo/notification/device-added.oga")
                elif action in ["remove", "unbind"] and now - last_usb_remove > 1:
                    last_usb_remove = now
                    dev_name = device_names_cache.get(devpath, get_device_name(current_event))
                    notify("Hardware", f"{dev_name} Disconnected", "drive-removable-media", "/usr/share/sounds/Pop/stereo/notification/device-removed.oga")
                    if devpath in device_names_cache:
                        del device_names_cache[devpath]
            
            elif current_event.get("SUBSYSTEM") == "power_supply":
                action = current_event.get("ACTION")
                now = time.time()
                status = get_ac_status()
                
                if action == "change":
                    if status == "1" and now - last_power_plug > 2:
                        last_power_plug = now
                        notify("Power", "Charger Connected", "battery-charging", "/usr/share/sounds/Pop/stereo/notification/power-plug.oga")
                    elif status == "0" and now - last_power_unplug > 2:
                        last_power_unplug = now
                        notify("Power", "Charger Disconnected", "battery-empty", "/usr/share/sounds/Pop/stereo/alert/power-unplug-battery-low.oga")
            
            current_event = {}
        elif "=" in line:
            try:
                key, val = line.split("=", 1)
                current_event[key] = val
            except ValueError:
                pass

if __name__ == "__main__":
    main()
