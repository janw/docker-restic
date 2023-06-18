FROM golang:1.19-alpine AS build_base

WORKDIR /src

# hadolint ignore=DL3018,DL3059
RUN apk add --no-cache git

FROM build_base as build_restic
ARG VERSION_RESTIC=

# hadolint ignore=DL3059
RUN GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
    go install "github.com/restic/restic/cmd/restic@v${VERSION_RESTIC}"

FROM build_base as build_runitor

# hadolint ignore=DL3059
RUN GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
    go install "bdd.fi/x/runitor/cmd/runitor@latest"

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

WORKDIR /
COPY backup.sh metrics.sh entrypoint.sh ./
COPY --from=build_restic /go/bin/restic /usr/bin
COPY --from=build_runitor /go/bin/runitor /usr/bin

ENTRYPOINT [ "tini", "--" ]
CMD ["/entrypoint.sh"]
