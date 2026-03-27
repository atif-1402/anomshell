#!/usr/bin/env bash 

if pgrep -x quickshell >/dev/null; then
  pkill -x quickshell
else
  uwsm-app -- quickshell >/dev/null 2>&1 &
fi
