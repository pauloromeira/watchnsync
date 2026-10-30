#!/bin/bash

# Configuration and defaults
export RCLONE_CONFIG="/config/rclone.conf"
WATCH_DIR="/watch"
DEBOUNCE_DELAY="${DEBOUNCE_DELAY:-60}"

RCLONE_PID=""

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

cleanup() {
    log "INFO" "Stopping watcher gracefully..."

    if [ -n "$RCLONE_PID" ]; then
        kill -TERM "$RCLONE_PID" 2>/dev/null
        wait "$RCLONE_PID" 2>/dev/null
    fi

    exit 0
}

# Graceful shutdown handling for Docker signals
trap cleanup SIGTERM SIGINT

log "INFO" "Starting watcher on $WATCH_DIR (DEBOUNCE_DELAY=${DEBOUNCE_DELAY})..."

# Main loop with debounce logic
while true; do
    CHANGES_DETECTED=false

    while true; do
        if [ "$CHANGES_DETECTED" = false ]; then
            if inotifywait -qq -r -e close_write -e moved_to -e create -e delete "$WATCH_DIR"; then
                CHANGES_DETECTED=true
                log "INFO" "Change detected. Waiting for activity to settle (${DEBOUNCE_DELAY}s)..."
            fi
        else
            if inotifywait -qq -r -t "$DEBOUNCE_DELAY" -e close_write -e moved_to -e create -e delete "$WATCH_DIR"; then
                log "INFO" "Additional change detected. Resetting timer..."
            else
                break
            fi
        fi
    done

    log "INFO" "Settling period finished. Triggering rclone..."
    log "DEBUG" "Running: rclone $@"

    rclone "$@" &
    RCLONE_PID=$!
    wait "$RCLONE_PID"
    RCLONE_STATUS=$?
    RCLONE_PID=""

    log "INFO" "Sync finished (exit code: $RCLONE_STATUS). Resuming watch..."
done
