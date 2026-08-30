#!/usr/bin/env python3
import sys
import os
import subprocess
import dbus

def get_devices():
    try:
        bus = dbus.SystemBus()
        manager = dbus.Interface(bus.get_object('org.bluez', '/'), 'org.freedesktop.DBus.ObjectManager')
        objects = manager.GetManagedObjects()
        devices = []
        for path, interfaces in objects.items():
            if 'org.bluez.Device1' in interfaces:
                dev = interfaces['org.bluez.Device1']
                addr = str(dev.get('Address', ''))
                name = str(dev.get('Name', dev.get('Alias', addr)))
                paired = bool(dev.get('Paired', False))
                connected = bool(dev.get('Connected', False))
                if paired or connected:
                    devices.append((addr, name, connected))
        devices.sort(key=lambda d: not d[2])
        return devices
    except Exception as e:
        print(f"Error listing devices: {e}", file=sys.stderr)
        return []

def select_file():
    try:
        res = subprocess.run(['zenity', '--file-selection', '--title=Select File to Send over Bluetooth'],
                             capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except Exception:
        return None

def select_device(devices):
    if not devices:
        subprocess.run(['notify-send', '-a', 'Bluetooth', 'Bluetooth Transfer', 'No paired Bluetooth devices found'])
        return None
    if len(devices) == 1:
        return devices[0][0], devices[0][1]
    
    cmd = ['zenity', '--list', '--title=Select Bluetooth Device', '--column=Address', '--column=Device Name']
    for addr, name, connected in devices:
        status_suffix = " (Connected)" if connected else ""
        cmd.extend([addr, name + status_suffix])
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        chosen = res.stdout.strip()
        for addr, name, _ in devices:
            if addr == chosen:
                return addr, name
        return chosen, chosen
    except Exception:
        return None

def send_file(addr, file_path):
    if not os.path.exists(file_path):
        subprocess.run(['notify-send', '-a', 'Bluetooth', '-u', 'critical', 'Bluetooth Transfer', f'File not found: {file_path}'])
        return False
    
    filename = os.path.basename(file_path)
    subprocess.run(['notify-send', '-a', 'Bluetooth', 'Bluetooth Transfer', f'Sending {filename} to {addr}...'])
    
    try:
        session_bus = dbus.SessionBus()
        client = dbus.Interface(session_bus.get_object('org.bluez.obex', '/org/bluez/obex'), 'org.bluez.obex.Client1')
        session_path = client.CreateSession(addr, {'Target': 'opp'})
        opp = dbus.Interface(session_bus.get_object('org.bluez.obex', session_path), 'org.bluez.obex.ObjectPush1')
        opp.SendFile(os.path.abspath(file_path))
        subprocess.run(['notify-send', '-a', 'Bluetooth', 'Bluetooth Transfer', f'Successfully sent {filename}!'])
        return True
    except Exception as e:
        subprocess.run(['notify-send', '-a', 'Bluetooth', '-u', 'critical', 'Bluetooth Transfer Failed', str(e)])
        return False

def main():
    target_addr = None
    file_path = None

    if len(sys.argv) > 1:
        arg1 = sys.argv[1]
        if os.path.exists(arg1):
            file_path = arg1
            if len(sys.argv) > 2:
                target_addr = sys.argv[2]
        else:
            target_addr = arg1
            if len(sys.argv) > 2 and os.path.exists(sys.argv[2]):
                file_path = sys.argv[2]

    if not file_path:
        file_path = select_file()
    if not file_path:
        return

    if not target_addr:
        devices = get_devices()
        dev_res = select_device(devices)
        if not dev_res:
            return
        target_addr, _ = dev_res

    send_file(target_addr, file_path)

if __name__ == '__main__':
    main()
