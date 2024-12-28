#!/bin/bash
set -uo pipefail

restic cat config
status=$?
echo "Check repo status $status"

if [ $status != 0 ]; then
    echo "Repository '${RESTIC_REPOSITORY}' does not exist. Initialize repo with 'restic init'."
    exit 1
fi

if [ -f "/hooks/pre-backup.sh" ]; then
    echo "Running pre-backup script."
    /hooks/pre-backup.sh
else
    echo "No /hooks/pre-backup.sh script found. Skipping."
fi

start=$(date +'%s')
echo "Starting Backup at $(date +"%Y-%m-%d %H:%M:%S")"
echo "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY:-}"
echo "RESTIC_PASSWORD: $(test -n "${RESTIC_PASSWORD}" && echo "<set>" || echo "<not set>")"
echo "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS:-}"
echo "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS:-}"
echo ""
echo "Directory tree:"

tree -xdp /data

# shellcheck disable=SC2086
restic backup /data ${RESTIC_JOB_ARGS}
rc_backup=$?
echo "Finished backup at $(date +"%Y-%m-%d %H:%M:%S")"
if [[ $rc_backup == 0 ]]; then
    echo "Backup Successful"
else
    echo "Backup Failed with Status ${rc_backup}"
    restic unlock
fi

if [ -n "${RESTIC_FORGET_ARGS:-}" ]; then
    echo "Forgetting old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"
    # shellcheck disable=SC2086
    restic forget ${RESTIC_FORGET_ARGS}
    rc_forget=$?
    echo "Finished forget at $(date +"%Y-%m-%d %H:%M:%S")"
    if [[ $rc_forget == 0 ]]; then
        echo "Forget Successful"
    else
        echo "Forget Failed with Status ${rc_forget}"
        restic unlock
    fi
else
    echo "No RESTIC_FORGET_ARGS provided. Skipping forget."
    rc_forget=0
fi

end=$(date +'%s')
echo "Finished Backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end - start)) seconds"

if [ -f "/hooks/post-backup.sh" ]; then
    echo "Running post-backup script."
    RC_BACKUP=$rc_backup RC_FORGET=$rc_forget /hooks/post-backup.sh
else
    echo "No /hooks/post-backup.sh script found. Skipping."
fi

exit $((rc_backup + rc_forget))
