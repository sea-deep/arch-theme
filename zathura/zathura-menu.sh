#!/usr/bin/env bash
# Trigger native Quickshell Zathura menu near cursor
qs ipc call zathuraMenu toggle 2>/dev/null || true
