FROM alpine:latest

RUN apk add --no-cache bash tzdata inotify-tools rclone

RUN mkdir -p /config /data

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
