#!/bin/sh
# Miku Dark Mode TTY Hardware Color Override
# This forces the raw Linux Virtual Terminal to use Miku Dark hex codes!

BLACK="1a1b26"
DARK_RED="f7768e"
DARK_GREEN="39c5bb"
DARK_YELLOW="e0af68"
DARK_BLUE="7aa2f7"
DARK_MAGENTA="bb9af7"
DARK_CYAN="7dcfff"
LIGHT_GRAY="a9b1d6"
DARK_GRAY="414868"
RED="f7768e"
GREEN="39c5bb"
YELLOW="e0af68"
BLUE="7aa2f7"
MAGENTA="bb9af7"
CYAN="7dcfff"
WHITE="c0caf5"

COLORS="${BLACK} ${DARK_RED} ${DARK_GREEN} ${DARK_YELLOW} ${DARK_BLUE} ${DARK_MAGENTA} ${DARK_CYAN} ${LIGHT_GRAY} ${DARK_GRAY} ${RED} ${GREEN} ${YELLOW} ${BLUE} ${MAGENTA} ${CYAN} ${WHITE}"

i=0
while [ $i -lt 16 ]; do
	printf "\033]P%X%s" ${i} "$(echo "$COLORS" | cut -d ' ' -f$(( i + 1)))"
	i=$(( i + 1 ))
done

clear # for fixing background artifacting after changing color
