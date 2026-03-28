#!/bin/bash

while true; do
    if pgrep -x waybar > /dev/null; then
        pkill -x waybar
        exit 0
    fi
    sleep 0.2
done
