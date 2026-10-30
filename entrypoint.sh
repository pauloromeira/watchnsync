#!/bin/bash

export RCLONE_CONFIG="/config/rclone.conf"
WATCH_DIR="/watch"
DELAY=${DEBOUNCE_DELAY:-60}

echo "Starting watcher on $WATCH_DIR (debounce delay: ${DELAY}s)..."

# Graceful shutdown handling for Docker signals
trap 'echo "Stopping watcher gracefully..."; exit 0' SIGTERM SIGINT

# Main loop with debounce logic
while true; do
    CHANGES_DETECTED=false

    while true; do
        if [ "$CHANGES_DETECTED" = false ]; then
            if inotifywait -qq -r -e close_write -e moved_to -e create -e delete "$WATCH_DIR"; then
                CHANGES_DETECTED=true
                echo "Change detected. Waiting for activity to settle (${DELAY}s)..."
            fi
        else
            if inotifywait -qq -r -t "$DELAY" -e close_write -e moved_to -e create -e delete "$WATCH_DIR"; then
                echo "Additional change detected. Resetting timer..."
            else
                break
            fi
        fi
    done

    echo "Settling period finished. Triggering rclone ${RCLONE_ACTION} to ${RCLONE_REMOTE}..."

    # Run rclone to sync the entire watch directory tree to the remote destination
    rclone "${RCLONE_ACTION:-copy}" $RCLONE_ARGS "$WATCH_DIR" "$RCLONE_REMOTE"

    echo "Sync finished. Resuming watch..."
done
