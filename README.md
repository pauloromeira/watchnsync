# Watch'n'Sync

> Watch with `inotify`, sync with `rclone`.

A lightweight Docker container that recursively monitors local directory changes with debounce support and syncs them automatically using `rclone`.

## Docker-compose example
```yml
services:
  watchnsync:
    image: ghcr.io/pauloromeira/watchnsync:latest
    container_name: watchnsync
    environment:
      - DEBOUNCE_DELAY=60
    command: sync --verbose --dry-run /watch myremote:backup
    volumes:
      - /path/to/host/rclone.conf:/config/rclone.conf:ro
      - /path/to/host/watch:/watch
    restart: unless-stopped
```
