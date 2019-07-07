FROM ubuntu:18.04

WORKDIR /tmp
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -q && apt-get install -y \
    ca-certificates \
    wget \
    bash \
    cron

# Get tini executable
ENV TINI_VERSION=0.18.0
ENV TINI_SHASUM="12d20136605531b09a2c2dac02ccee85e1b874eb322ef6baf7561cd93f93c855"
ENV TINI_BASEURL="https://github.com/krallin/tini/releases/download"

RUN \
    wget -nv -O /usr/bin/tini ${TINI_BASEURL}/v${TINI_VERSION}/tini && \
    echo "${TINI_SHASUM} /usr/bin/tini" | sha256sum -c - && \
    chmod +x /usr/bin/tini

# Get restic executable
ENV RESTIC_VERSION="0.9.5"
ENV RESTIC_SHASUM="08cd75e56a67161e9b16885816f04b2bf1fb5b03bc0677b0ccf3812781c1a2ec"
ENV RESTIC_BASEURL="https://github.com/restic/restic/releases/download"

RUN \
    wget -nv ${RESTIC_BASEURL}/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2 && \
    echo "${RESTIC_SHASUM} restic_${RESTIC_VERSION}_linux_amd64.bz2" | sha256sum -c - && \
    bzip2 -d restic_${RESTIC_VERSION}_linux_amd64.bz2 && \
    mv restic_${RESTIC_VERSION}_linux_amd64 /usr/bin/restic && \
    chmod +x /usr/bin/restic && \
    \
    apt-get autoclean

WORKDIR /
COPY backup.sh entry.sh ./

# # /data is the dir where you have to put the data to be backed up
VOLUME /data
VOLUME /repo
VOLUME /logs

ENTRYPOINT ["tini", "--"]
CMD ["/entry.sh"]

