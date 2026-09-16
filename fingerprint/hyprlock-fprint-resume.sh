#!/bin/bash

# This script runs on system suspend and resume.
# 
# Background: The python3-validity driver for the Prometheus fingerprint 
# sensor must be fully restarted on resume to fix a hardware wedge issue.
# This restart takes about 6-8 seconds. 
# 
# Meanwhile, hyprlock (started via before-sleep) is already running and 
# its PAM module (pam_fprint_grosshack) fails when the driver restarts.
# To fix this, we wait for the driver to finish starting, and if hyprlock 
# is still active, we inject an 'Enter' keystroke. This causes hyprlock 
# to fail the empty password attempt and loop back to the start of the 
# PAM stack, seamlessly re-activating the fingerprint reader!

if [ "$1" = "post" ]; then
    # Run in background to avoid blocking system resume
    (
        # Wait for python3-validity to finish uploading firmware
        sleep 8
        
        # Only inject keystroke if hyprlock is actually running
        if pgrep -x hyprlock > /dev/null; then
            HYPRLOCK_PID=$(pgrep -x hyprlock | head -n1)
            HYPRLOCK_USER=$(ps -o user= -p "$HYPRLOCK_PID")
            HYPRLOCK_UID=$(id -u "$HYPRLOCK_USER")
            
            for socket in /run/user/$HYPRLOCK_UID/wayland-*; do
                if [ -S "$socket" ]; then
                    WAYLAND_DISPLAY=$(basename "$socket")
                    # Strict validation to prevent command injection from malicious socket names
                    if [[ "$WAYLAND_DISPLAY" =~ ^wayland-[0-9]+$ ]]; then
                        su - "$HYPRLOCK_USER" -c "XDG_RUNTIME_DIR=/run/user/$HYPRLOCK_UID WAYLAND_DISPLAY='$WAYLAND_DISPLAY' wtype -k Return"
                    fi
                fi
            done
        fi
    ) &
fi
