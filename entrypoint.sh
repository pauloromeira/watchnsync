#!/bin/bash

# Configuration and defaults
export RCLONE_CONFIG="/config/rclone.conf"
WATCH_DIR="/watch"
DEBOUNCE_DELAY=${DEBOUNCE_DELAY:-60}

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

log "INFO" "Starting watcher on $WATCH_DIR (DEBOUNCE_DELAY=${DEBOUNCE_DELAY})..."

# Graceful shutdown handling for Docker signals
trap 'log "INFO" "Stopping watcher gracefully..."; exit 0' SIGTERM SIGINT

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
    rclone "$@"

    log "INFO" "Sync finished. Resuming watch..."
done
