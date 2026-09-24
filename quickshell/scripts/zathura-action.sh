#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  Zathura Action Dispatcher
#  Executes Zathura actions via D-Bus (instant) or wtype (keystrokes)
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

ACTION="${1:-}"
[[ -z "$ACTION" ]] && exit 0

# Discover active Zathura D-Bus instance
DBUS_DEST=""
ACTIVE_PID=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null || true)
if [[ -n "$ACTIVE_PID" && "$ACTIVE_PID" != "null" ]]; then
    if busctl --user status "org.pwmt.zathura.PID-$ACTIVE_PID" >/dev/null 2>&1; then
        DBUS_DEST="org.pwmt.zathura.PID-$ACTIVE_PID"
    fi
fi
if [[ -z "$DBUS_DEST" ]]; then
    DBUS_DEST=$(busctl --user list 2>/dev/null | awk '/org\.pwmt\.zathura/ {print $1}' | tail -n 1 || true)
fi

# Instant D-Bus execution for supported actions (zero focus dependency)
case "$ACTION" in
    recolor)
        if [[ -n "$DBUS_DEST" ]]; then
            busctl --user call "$DBUS_DEST" /org/pwmt/zathura org.pwmt.zathura ExecuteCommand s "set recolor!" >/dev/null 2>&1 && exit 0
        fi
        ;;
    copy_path)
        if [[ -n "$DBUS_DEST" ]]; then
            FILE=$(busctl --user get-property "$DBUS_DEST" /org/pwmt/zathura org.pwmt.zathura filename 2>/dev/null | awk -F'"' '{print $2}' || true)
            if [[ -n "$FILE" ]]; then
                printf "%s" "$FILE" | wl-copy
                printf "%s" "$FILE" | wl-copy --primary 2>/dev/null || true
                exit 0
            fi
        fi
        ;;
    print)
        if [[ -n "$DBUS_DEST" ]]; then
            busctl --user call "$DBUS_DEST" /org/pwmt/zathura org.pwmt.zathura ExecuteCommand s "print" >/dev/null 2>&1 && exit 0
        fi
        ;;
    quit)
        if [[ -n "$DBUS_DEST" ]]; then
            busctl --user call "$DBUS_DEST" /org/pwmt/zathura org.pwmt.zathura ExecuteCommand s "quit" >/dev/null 2>&1 && exit 0
        fi
        ;;
esac

# For keystroke actions: wait for active window to settle back to Zathura after menu dismissal
for _ in {1..20}; do
    current_class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' || true)
    if [[ "$current_class" == *"zathura"* ]]; then
        break
    fi
    sleep 0.015
done
sleep 0.04

# Send corresponding shortcut key via wtype
case "$ACTION" in
    recolor)
        wtype -k d 2>/dev/null || true
        ;;
    copy_path)
        wtype -k y 2>/dev/null || true
        ;;
    print)
        wtype -M ctrl -k p -m ctrl 2>/dev/null || true
        ;;
    quit)
        wtype -k q 2>/dev/null || true
        ;;
    open)
        wtype -k o 2>/dev/null || wtype -M ctrl -k o -m ctrl 2>/dev/null || true
        ;;
    rotate_cw)
        wtype -k r 2>/dev/null || true
        ;;
    rotate_ccw)
        wtype -M shift -k r -m shift 2>/dev/null || wtype -k R 2>/dev/null || true
        ;;
    zoom_in)
        wtype -k equal 2>/dev/null || wtype -k plus 2>/dev/null || true
        ;;
    zoom_out)
        wtype -k minus 2>/dev/null || true
        ;;
    zoom_100)
        wtype -k 0 2>/dev/null || true
        ;;
    fit_width)
        wtype -k w 2>/dev/null || true
        ;;
    fit_page)
        wtype -k f 2>/dev/null || true
        ;;
    table_of_contents)
        wtype -k Tab 2>/dev/null || wtype -k i 2>/dev/null || true
        ;;
    search)
        wtype -k slash 2>/dev/null || wtype -M ctrl -k f -m ctrl 2>/dev/null || true
        ;;
    two_page)
        wtype -M shift -k d -m shift 2>/dev/null || wtype -k D 2>/dev/null || true
        ;;
    reload)
        wtype -k F5 2>/dev/null || wtype -M ctrl -k r -m ctrl 2>/dev/null || true
        ;;
    fullscreen)
        wtype -k F11 2>/dev/null || true
        ;;
    *)
        exit 1
        ;;
esac
