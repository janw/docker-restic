FROM restic/restic:0.10.0

ENV RESTIC_REPOSITORY=/target
ENV RESTIC_PASSWORD=
ENV RESTIC_JOB_ARGS=
ENV RESTIC_FORGET_ARGS=
ENV HEALTHCHECK_URL=

RUN set -e; \
    apk add --update --no-cache rclone curl bash; \
    mkdir /.cache; \
    chgrp -R 0 /.cache; \
    chmod -R g=u /.cache

# /data is the dir where you have to put the data to be backed up
VOLUME /data

# /target is where an externally mounted repo should be
VOLUME /target

COPY backup.sh /backup.sh

WORKDIR "/"

ENTRYPOINT ["/backup.sh"]
