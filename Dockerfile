FROM alpine:latest

RUN apk add --no-cache inotify-tools bash rclone tzdata

RUN mkdir -p /data /config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
