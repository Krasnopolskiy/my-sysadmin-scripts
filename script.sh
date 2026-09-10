#!/bin/bash
# Resource monitor: appends free -h, df -h and uptime to monitor.log every N seconds.

INTERVAL=5
LOG_FILE="monitor.log"

while true; do
    echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"
    free -h >> "$LOG_FILE"
    df -h >> "$LOG_FILE"
    uptime >> "$LOG_FILE"
    sleep "$INTERVAL"
done
