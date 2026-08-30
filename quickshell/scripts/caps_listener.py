#!/usr/bin/env python3
import glob
import os
import select
import struct
import sys

def get_sys_state():
    for p in glob.glob('/sys/class/leds/*capslock/brightness'):
        try:
            with open(p, 'r') as f:
                if f.read().strip() == '1':
                    return True
        except Exception:
            pass
    return False

# Emit initial state immediately
current_state = get_sys_state()
sys.stdout.write("1\n" if current_state else "0\n")
sys.stdout.flush()

fds = []
for p in set(glob.glob('/dev/input/by-path/*event-kbd')):
    try:
        fd = os.open(p, os.O_RDONLY | os.O_NONBLOCK)
        fds.append(fd)
    except Exception:
        pass

# struct input_event: timeval (16 bytes on 64-bit), u16 type, u16 code, s32 value -> 24 bytes
EVENT_FORMAT = "qqHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)
EV_LED = 17
LED_CAPSL = 1

while True:
    try:
        r, _, _ = select.select(fds, [], [], 2.0)
        if not r:
            st = get_sys_state()
            if st != current_state:
                current_state = st
                sys.stdout.write("1\n" if current_state else "0\n")
                sys.stdout.flush()
            continue

        for fd in r:
            while True:
                try:
                    data = os.read(fd, EVENT_SIZE)
                    if not data or len(data) < EVENT_SIZE:
                        break
                    _, _, ev_type, ev_code, ev_val = struct.unpack(EVENT_FORMAT, data)
                    if ev_type == EV_LED and ev_code == LED_CAPSL:
                        new_state = (ev_val == 1)
                        if new_state != current_state:
                            current_state = new_state
                            sys.stdout.write("1\n" if current_state else "0\n")
                            sys.stdout.flush()
                except (BlockingIOError, OSError):
                    break
    except Exception:
        pass
