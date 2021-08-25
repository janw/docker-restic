#!/bin/bash
set -euo pipefail

SNAPSHOTS=$(restic --no-lock snapshots --json)

snap_attr() {
    local query_suffix="$1"
    echo "$SNAPSHOTS" | jq -r ". | $query_suffix"
}

SNAP_TAGS=$(snap_attr 'last | "username=\"" + (.username) + "\", hostname=\"" + (.hostname) + "\""')
BASIC_TAGS="repository=\"$RESTIC_REPOSITORY\""

cat <<EOF
# HELP restic_snapshot_count Number of existing snapshots
# TYPE restic_snapshot_count gauge
restic_snapshot_count{$BASIC_TAGS} $(snap_attr length)

# HELP restic_snapshot_latest_timestamp Timestamp of the latest existing snapshot
# TYPE restic_snapshot_latest_timestamp gauge
restic_snapshot_latest_timestamp{$BASIC_TAGS,$SNAP_TAGS} $(snap_attr 'last.time[:19] + "Z" | fromdate')

# HELP restic_snapshot_oldest_timestamp Timestamp of the oldest existing snapshot
# TYPE restic_snapshot_oldest_timestamp gauge
restic_snapshot_latest_timestamp{$BASIC_TAGS,$SNAP_TAGS} $(snap_attr 'first.time[:19] + "Z" | fromdate')
EOF
