#!/bin/bash
set -e

# Prepopulate the RESTIC_REPOSITORY variable for container use
export RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-/target}"

# Backwards compatiblity with HEALTHCHECK_URL variable
_HEALTHCHECK_UUID="${HEALTHCHECK_URL: -36}"
export CHECK_UUID="${CHECK_UUID:-$_HEALTHCHECK_UUID}"

exec runitor "$@" -- /backup.sh
