#!/usr/bin/env bash

export RCLONE_CONFIG="/config/rclone.conf"

DEBOUNCE_DELAY="${DEBOUNCE_DELAY:-60}"
WATCH_EVENTS="${WATCH_EVENTS:-close_write,create,delete,move}"
WATCH_DIR="/watch"

EVENT_FIFO="$(mktemp -d)/events"
mkfifo "$EVENT_FIFO"

RCLONE_PID=""

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"
}

cleanup() {
    log INFO "Stopping watcher..."

    if [[ -n "$RCLONE_PID" ]]; then
        kill -TERM "$RCLONE_PID" 2>/dev/null || true
        wait "$RCLONE_PID" 2>/dev/null || true
    fi

    rm -rf "$(dirname "$EVENT_FIFO")"
}

trap cleanup EXIT
trap 'exit 0' TERM INT

inotifywait \
    --monitor \
    --recursive \
    --event "$WATCH_EVENTS" \
    --timefmt '%s' \
    --format '%T' \
    "$WATCH_DIR" > "$EVENT_FIFO" &

log INFO "Watching $WATCH_DIR (debounce: ${DEBOUNCE_DELAY}s, events: ${WATCH_EVENTS})..."

while IFS= read -r; do

    log INFO "Change detected. Waiting for activity to settle..."

    while IFS= read -r -t "$DEBOUNCE_DELAY"; do
      log INFO "Additional change detected. Resetting timer..."
    done || true

    log INFO "Activity settled. Running rclone..."
    log DEBUG "Running: rclone $@"

    rclone "$@" &
    RCLONE_PID=$!
    wait "$RCLONE_PID"
    RCLONE_STATUS=$?
    RCLONE_PID=""

    log INFO "Rclone finished (exit code: $RCLONE_STATUS)."

done < "$EVENT_FIFO"
