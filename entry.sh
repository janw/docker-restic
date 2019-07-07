#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# By default backup every 6 hours
BACKUP_CRON=${BACKUP_CRON:-"* */6 * * *"}
export RESTIC_REPOSITORY=${RESTIC_REPOSITORY:-"/repo"}


if [ -z "${RESTIC_PASSWORD:-}" ] && \
    [ -z "${RESTIC_PASSWORD_FILE:-}" ] && \
    [ -z "${RESTIC_PASSWORD_COMMAND:-}" ]; then
    echo "One of the RESTIC_PASSWORD[_FILE|_COMMAND] env vars is required."
    exit 1
fi

# Check if unsupported -r/--repo was used
if [ $(echo "${RESTIC_JOB_ARGS:-}" | grep -cE "\s(\-r|\-\-repo)(\=|\s)") -ne 0 ]; then
    echo "Restic command line option '-r|--repo' not supported. Use RESTIC_REPOSITORY env var instead."
    exit 1
fi

# Init repository if necessary
if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
    echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
    restic init || true
fi

# Pass on relevant variables
declare -p | grep -Ev 'BASH|EUID|PPID|SHELLOPTS|UID' > /backup.env

# Start the cron daemon
echo "Setup backup cron job with cron expression BACKUP_CRON: ${BACKUP_CRON}"
echo -e "SHELL=/bin/bash\nBASH_ENV=/backup.env\n${BACKUP_CRON} /backup.sh > /proc/1/fd/1 2>/proc/1/fd/2" | crontab

exec cron -f
