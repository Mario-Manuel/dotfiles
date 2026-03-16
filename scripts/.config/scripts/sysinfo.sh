#!/usr/bin/env zsh

# idade da instalação do sistema
os_age=$(( ($(date +%s) - $(stat -c %W /)) / 86400 ))

# última atualização
last_update=$(grep "starting full system upgrade" /var/log/pacman.log | tail -1 | cut -d'[' -f2 | cut -d']' -f1)

# dias desde a última atualização
if [[ -n "$last_update" ]]; then
    last_update_days=$(( ($(date +%s) - $(date -d "$last_update" +%s)) / 86400 ))
else
    last_update_days="unknown"
fi

# info do fastfetch
info=$(fastfetch --pipe true --logo none --structure Kernel:Uptime:Packages:Disk)

info=$(echo "$info" | awk -v age="$os_age days" -v upd="$last_update_days days ago" '
/Uptime:/ {
    print
    print "OS Age: " age
    print "Last Update: " upd
    next
}
{print}
')

notify-send -t 9000 "💻 System Info" "$info"
