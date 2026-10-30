FROM alpine:latest

RUN apk add --no-cache inotify-tools bash rclone

RUN mkdir -p /watch /config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
