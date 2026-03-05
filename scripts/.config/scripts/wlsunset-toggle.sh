#!/usr/bin/env zsh

if pgrep -x wlsunset >/dev/null; then
    pkill wlsunset
else
    wlsunset -S 07:00 -s 19:00 -d 30 -t 3500 &
fi
