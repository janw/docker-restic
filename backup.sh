#!/bin/bash
set -uo pipefail

log_tmp_file=$(mktemp)
echo "Will write logs to $log_tmp_file"

logLast() {
    echo "$1" | tee -a "$log_tmp_file"
}

healthcheck() {
    local suffix=${1:-}
    if [ -n "$HEALTHCHECK_URL" ]; then
        echo -n "Reporting healthcheck $suffix ... "
        curl -fSsL --retry 3 -X POST \
            --user-agent "docker-restic/0.1.0" \
            --data-binary "@${log_tmp_file}" "${HEALTHCHECK_URL}${suffix}"
        echo
    else
        echo "No HEALTHCHECK_URL provided. Skipping healthcheck."
    fi
}

healthcheck /start

restic snapshots &>/dev/null
status=$?
logLast "Check Repo status $status"

if [ $status != 0 ]; then
    logLast "Repository '${RESTIC_REPOSITORY}' does not exist. Initialize repo with 'restic init'."
    healthcheck /fail
    exit 1
fi

if [ -f "/hooks/pre-backup.sh" ]; then
    logLast "Running pre-backup script."
    /hooks/pre-backup.sh 2>&1 | tee -a "$log_tmp_file"
else
    logLast "No /hooks/pre-backup.sh script found. Skipping."
fi

start=$(date +'%s')
logLast "Starting Backup at $(date +"%Y-%m-%d %H:%M:%S")"
logLast "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY:-}"
logLast "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS:-}"
logLast "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS:-}"
logLast ""
logLast "Directory tree:"

tree -dph -L 3 /data | tee -a "$log_tmp_file"

# shellcheck disable=SC2086
restic backup /data ${RESTIC_JOB_ARGS} "$@" 2>&1 | tee -a "$log_tmp_file"
rc_backup=$?
logLast "Finished backup at $(date +"%Y-%m-%d %H:%M:%S")"
if [[ $rc_backup == 0 ]]; then
    logLast "Backup Successful"
else
    logLast "Backup Failed with Status ${rc_backup}"
    restic unlock
fi

if [ -n "${RESTIC_FORGET_ARGS:-}" ]; then
    logLast "Forgetting old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"
    # shellcheck disable=SC2086
    restic forget ${RESTIC_FORGET_ARGS} 2>&1 | tee -a "$log_tmp_file"
    rc_forget=$?
    logLast "Finished forget at $(date)"
    if [[ $rc_forget == 0 ]]; then
        logLast "Forget Successful"
    else
        logLast "Forget Failed with Status ${rc_forget}"
        restic unlock
    fi
else
    logLast "No RESTIC_FORGET_ARGS provided. Skipping forget."
fi

end=$(date +'%s')
logLast "Finished Backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end - start)) seconds"

if [ -f "/hooks/post-backup.sh" ]; then
    logLast "Running post-backup script."
    RC_BACKUP=$rc_backup RC_FORGET=$rc_forget \
        /hooks/post-backup.sh 2>&1 | tee -a "$log_tmp_file"
else
    logLast "No /hooks/post-backup.sh script found. Skipping."
fi

if [ $rc_backup = 0 ]; then
    healthcheck
else
    healthcheck /fail
fi
