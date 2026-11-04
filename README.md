# Watch'n'Sync

> Watch with `inotify`, sync with `rclone`.

A lightweight Docker container that recursively monitors local directory changes using `inotify` and automatically runs `rclone` to sync them, with configurable debounce support.

## Docker Compose example

```yaml
services:
  watchnsync:
    image: ghcr.io/pauloromeira/watchnsync:latest
    container_name: watchnsync
    environment:
      - TZ=<timezone>  # set your local timezone for log timestamps
      - DEBOUNCE_DELAY=60  # wait in seconds for changes to settle (default: 60)
      - WATCH_EVENTS=close_write,create,move  # events to watch (default: close_write,create,move,delete)
      - RUN_ON_START=true  # run rclone once on startup, before starting to watch for changes (default: false)
    command: copy --verbose --dry-run /data myremote:backup
    volumes:
      - /path/to/host/rclone.conf:/config/rclone.conf:ro
      - /path/to/host/data:/data
    restart: unless-stopped
```

The example above uses `--dry-run`, so no files will actually be copied. Remove this flag to perform the copy operation.
