#!/bin/sh
set -e

DATA_DIR="$PWD/test-data"
REPO_DIR="$PWD/test-repo"

if [ ! -d "$REPO_DIR" ]; then
    mkdir -p "$REPO_DIR"
fi

if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR"
    echo "Test File" > "$DATA_DIR/testfile.txt"
fi

echo "Removing old 'backup-test' container if exists"
docker rm -f -v backup-test || true

echo "Building current image"
make build

echo "Start backup-test container. Backup of test-data to test-repo"
docker run --privileged --name backup-test \
--hostname "test-instance" \
-e "RESTIC_PASSWORD=test" \
-e "RESTIC_JOB_ARGS=--tag=test" \
-e "RESTIC_FORGET_ARGS=--keep-last 10" \
-e "HEALTHCHECK_URL" \
-v "$DATA_DIR":/data \
-v "$REPO_DIR":/target \
-t ghcr.io/janw/restic
