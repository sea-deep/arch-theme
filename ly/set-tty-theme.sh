#!/bin/bash
# Set Miku/Tokyo Night 16-color ANSI palette on TTYs for Ly display manager

# Kitty / Miku Hex Color Palette
# P0: Black (#1a1b26)      - Background
# P1: Red (#f7768e)
# P2: Green (#9ece6a)
# P3: Yellow (#e0af68)
# P4: Blue (#7aa2f7)       - Focused title
# P5: Magenta (#bb9af7)
# P6: Cyan (#39c5bb)       - Miku Teal / Borders
# P7: White (#c0caf5)      - Foreground text
# P8: Bright Black (#414868)
# P9: Bright Red (#f7768e)
# PA: Bright Green (#9ece6a)
# PB: Bright Yellow (#e0af68)
# PC: Bright Blue (#7dcfff)
# PD: Bright Magenta (#bb9af7)
# PE: Bright Cyan (#39c5bb)
# PF: Bright White (#a9b1d6)

PALETTE="\e]P01a1b26\e]P1f7768e\e]P29ece6a\e]P3e0af68\e]P47aa2f7\e]P5bb9af7\e]P639c5bb\e]P7c0caf5\e]P8414868\e]P9f7768e\e]PA9ece6a\e]PBe0af68\e]PC7dcfff\e]PDbb9af7\e]PE39c5bb\e]PFa9b1d6"

for tty in /dev/tty[1-6]; do
    if [ -w "$tty" ]; then
        printf "%b" "$PALETTE" > "$tty" 2>/dev/null || true
    fi
done
