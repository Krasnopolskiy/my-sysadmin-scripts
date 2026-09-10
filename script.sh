#!/bin/bash
#
# Resource monitor. Every INTERVAL seconds appends a timestamped block of
# free -h, df -h and uptime to monitor.log.
#
#   ./script.sh      loop until Ctrl+C
#   ./script.sh 3    take 3 snapshots, then exit
#
# No `set -e`: a failing probe goes to the log and the loop keeps running.
set -uo pipefail

INTERVAL=5
MAX_LOG_BYTES=$((1024 * 1024))
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${MONITOR_LOG:-$SCRIPT_DIR/monitor.log}"
SNAPSHOTS="${1:-0}"                  # 0 = unlimited

err() { echo "error: $*" >&2; }

on_stop() {
    echo "--- monitor stopped $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"
    exit 0
}
trap on_stop INT TERM

check_args() {
    case "$SNAPSHOTS" in
        ''|*[!0-9]*)
            err "snapshot count must be a non-negative integer, got '$SNAPSHOTS'"
            echo "usage: $0 [snapshots]" >&2
            exit 2
            ;;
    esac
}

check_deps() {
    local missing=() cmd
    for cmd in free df uptime date; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    [ ${#missing[@]} -eq 0 ] || { err "missing commands: ${missing[*]}"; exit 1; }
}

prepare_log() {
    local dir; dir="$(dirname "$LOG_FILE")"
    [ -d "$dir" ] || mkdir -p "$dir" || { err "cannot create $dir"; exit 3; }
    touch "$LOG_FILE" 2>/dev/null || { err "cannot write to $LOG_FILE"; exit 3; }
    rotate_log
}

# Move an oversized log aside so the live file stays readable.
rotate_log() {
    local size; size=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$size" -gt "$MAX_LOG_BYTES" ]; then
        mv "$LOG_FILE" "$LOG_FILE.1"
        echo "--- rotated at $MAX_LOG_BYTES bytes, previous log kept as $(basename "$LOG_FILE").1 ---" > "$LOG_FILE"
    fi
}

probe() {
    local title="$1"; shift
    echo "[$title]"
    "$@" 2>&1 || echo "  ($* failed)"
}

snapshot() {
    {
        echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---"
        probe "free -h" free -h
        echo
        probe "df -h" df -h
        echo
        probe "uptime" uptime
        echo
    } >> "$LOG_FILE"
}

main() {
    check_args
    check_deps
    prepare_log

    if [ "$SNAPSHOTS" -eq 0 ]; then
        echo "monitoring every ${INTERVAL}s -> $LOG_FILE (Ctrl+C to stop)"
    else
        echo "monitoring ${SNAPSHOTS} snapshot(s) every ${INTERVAL}s -> $LOG_FILE"
    fi

    local count=0
    while true; do
        rotate_log
        snapshot
        count=$((count + 1))
        [ "$SNAPSHOTS" -ne 0 ] && [ "$count" -ge "$SNAPSHOTS" ] && break
        sleep "$INTERVAL"
    done

    [ "$SNAPSHOTS" -ne 0 ] && echo "done: $count snapshot(s) -> $LOG_FILE"
}

main
