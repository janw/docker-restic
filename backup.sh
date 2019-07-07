#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

export RESTIC_REPOSITORY=${RESTIC_REPOSITORY:-/repo}
RESTIC_DATA_DIRECTORY=${RESTIC_DATA_DIRECTORY:-/data}
RESTIC_TAG=${RESTIC_TAG:-}
RESTIC_JOB_ARGS=${RESTIC_JOB_ARGS:-}
RESTIC_FORGET_ARGS=${RESTIC_FORGET_ARGS:-}
RESTIC_LAST_LOGFILE=${RESTIC_LAST_LOGFILE:-"/logs/backup-last.log"}
RESTIC_LAST_ERROR_LOGFILE=${RESTIC_LAST_ERROR_LOGFILE:-"/logs/backup-error-last.log"}

logLast() {
  echo "$1" >> "${RESTIC_LAST_LOGFILE}"
}

finish() {
    rc=$?
    end=`date +%s`
    echo $(
    if [ $rc -eq 0 ]; then
        echo "==> Finished successfully"
    elif [ $rc -eq 1 ]; then
        echo "==> Backup failed"
    elif [ $rc -eq 2 ]; then
        echo "==> Forget failed"
    fi
    ) "at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds" | \
        tee -a "${RESTIC_LAST_LOGFILE}"
    if [ $rc -ne 0 ]; then
        echo "==> Removing stale locks" | tee -a "${RESTIC_LAST_LOGFILE}"
        restic unlock > >(tee -a $RESTIC_LAST_LOGFILE) 2>&1 || true
        cp "${RESTIC_LAST_LOGFILE}" "${RESTIC_LAST_ERROR_LOGFILE}"
        kill 1
    fi
}
trap finish EXIT

# Start the backup with logging the state of variables first
start=`date +%s`
echo "==> Starting backup at $(date +"%Y-%m-%d %H:%M:%S")" | tee ${RESTIC_LAST_LOGFILE}
logLast "RESTIC_TAG: ${RESTIC_TAG}"
logLast "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
logLast "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS}"
logLast "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
logLast "RESTIC_DATA_DIRECTORY: ${RESTIC_DATA_DIRECTORY}"

# If RESTIG_TAG is set append it to the job command
RESTIC_JOB_CMD="restic backup ${RESTIC_DATA_DIRECTORY} ${RESTIC_JOB_ARGS:-}"
if [ ! -z "${RESTIC_TAG}" ]; then
	RESTIC_JOB_CMD="${RESTIC_JOB_CMD} --tag=${RESTIC_TAG}"
fi

# Do not save full backup log to logfile but to backup-last.log
eval "$RESTIC_JOB_CMD" > >(tee -a $RESTIC_LAST_LOGFILE) 2>&1 || exit 1
logLast "Finished backup"

# If got RESTIC_FORGET_ARGS run forget
if [ ! -z "${RESTIC_FORGET_ARGS}" ]; then
    echo "==> Starting forget at $(date +"%Y-%m-%d %H:%M:%S")" | \
        tee -a "${RESTIC_LAST_LOGFILE}"
    eval "restic forget ${RESTIC_FORGET_ARGS}" > >(tee -a $RESTIC_LAST_LOGFILE) 2>&1 || exit 2
    logLast "Finished forget"
fi
