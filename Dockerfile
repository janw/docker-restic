FROM ghcr.io/restic/restic:0.16.2 AS restic
FROM ghcr.io/bdd/runitor:v1.3.0-alpine AS runitor

FROM docker.io/library/alpine:3

ENV RESTIC_REPOSITORY=/target
ENV RESTIC_PASSWORD=
ENV RESTIC_JOB_ARGS=
ENV RESTIC_FORGET_ARGS=
ENV HEALTHCHECK_URL=

# hadolint ignore=DL3018
RUN set -e; \
    apk add --update --no-cache \
        rclone curl bash tini tree \
        ca-certificates fuse openssh-client tzdata jq \
    ; \
    mkdir /.cache; \
    chgrp -R 0 /.cache; \
    chmod -R g=u /.cache

# /data is the dir where you have to put the data to be backed up
VOLUME /data

# /target is where an externally mounted repo should be
VOLUME /target

WORKDIR /
COPY backup.sh metrics.sh entrypoint.sh ./
COPY --from=restic /usr/bin/restic /usr/bin/
COPY --from=runitor /usr/local/bin/runitor /usr/bin

ENTRYPOINT [ "tini", "--" ]
CMD ["/entrypoint.sh"]
