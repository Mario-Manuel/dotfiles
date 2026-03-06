#!/usr/bin/env zsh

os_age=$(( ($(date +%s) - $(stat -c %W /)) / 86400 ))

info=$(fastfetch --pipe true --logo none --structure Kernel:Uptime:Packages:Disk)

info=$(echo "$info" | awk -v age="$os_age days" '
/Uptime:/ {print; print "OS Age: " age; next}
{print}
')

notify-send -t 9000 "💻 System Info" "$info"
