#!/bin/bash

conflicting_processes=(
    "waybar"
    "mako"
)

while true; do
    still_running=0

    for proc in "${conflicting_processes[@]}"; do
        if pgrep -x "$proc" > /dev/null; then
            pkill -x "$proc"
            still_running=1
        fi
    done

    if [[ "$still_running" -eq 0 ]]; then
        exit 0
    fi
    sleep 0.2
done
