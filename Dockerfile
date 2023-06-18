FROM golang:1.19-alpine AS builder
ARG VERSION_RESTIC=

WORKDIR /src

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go install github.com/restic/restic/cmd/restic@v${VERSION_RESTIC}

FROM alpine:3

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

COPY backup.sh /usr/local/bin/backup
COPY metrics.sh /usr/local/bin/metrics
COPY --from=builder /go/bin/restic /usr/bin

WORKDIR "/"

ENTRYPOINT [ "tini", "--" ]
CMD ["backup"]
