# Restic Backup Docker Container

A docker container to automate [restic backups](https://restic.github.io/)

This container runs restic backups as one-off jobs and supports reporting to [healthchecks.io](https://healthchecks.io)

* Easy setup and maintenance
* Support for different Restic targets configurable through environment variables
* Support `restic mount` inside the container to browse the backup files

**Container**: [ghcr.io/janw/restic](https://github.com/janw/docker-restic/pkgs/container/restic)

Latest

```bash
docker pull ghcr.io/janw/restic
```

Please don't hesitate to report any issue you find. Thanks.

## Environment variables

The container is setup by setting [environment variables](https://docs.docker.com/engine/reference/run/#/env-environment-variables) and [volumes](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems).

* `RESTIC_PASSWORD` — **Required.** The password for the restic repository. Will also be used for restic init during first start when the repository is not initialized.
* `RESTIC_REPOSITORY` — Optional. The location of the restic repository. Defaults to `/target`, so externally mounted repositories (NFS, SSHFS, etc.) should be mounted at `/target` into the container. For S3, this should be `s3:https://s3.amazonaws.com/BUCKET_NAME`
* `RESTIC_FORGET_ARGS` — Optional.`restic forget` will be run when this is set with the given arguments after each backup. Example argument:

    ```-e "RESTIC_FORGET_ARGS=--prune --keep-last 10 --keep-hourly 24 --keep-daily 7 --keep-weekly 52 --keep-monthly 120 --keep-yearly 100"```

* `RESTIC_JOB_ARGS` — Optional. Allows to specify extra arguments to the backup job such as limiting bandwith with `--limit-upload` or excluding file masks with `--exclude`.
* Of course other [Restic environment configuration variables](https://restic.readthedocs.io/en/latest/040_backup.html#environment-variables) are supported as well.

## Volumes

* `/data` - This is the data that gets backed up. Just [mount](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems) it to wherever you want.
* `/target` - This is the default target repository to back up to. Just [mount](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems) your repository there, or adjust the `RESTIC_REPOSITORY` variable if you require other means of connecting to the repository (S3, Backblaze B2, etc.).

## Set the hostname

Since restic saves the hostname with each snapshot and the hostname of a docker container is it's id you might want to customize this by setting the hostname of the container to another value.

Either by setting the [environment variable](https://docs.docker.com/engine/reference/run/#env-environment-variables) `HOSTNAME` or with `--hostname` in the [network settings](https://docs.docker.com/engine/reference/run/#network-settings)

## Backup to SFTP

Since restic needs a **password less login** to the SFTP server make sure you can do `sftp user@host` from inside the container. If you can do so from your host system, the easiest way is to just mount your `.ssh` folder conaining the authorized cert into the container by specifying `-v ~/.ssh:/root/.ssh` as argument for `docker run`.

Now you can simply specify the restic repository to be an [SFTP repository](https://restic.readthedocs.io/en/stable/Manual/#create-an-sftp-repository).

```bash
-e "RESTIC_REPOSITORY=sftp:user@host:/tmp/backup"
```

## Backups in a Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-to-backblaze-b2
  namespace: backups
spec:
  schedule: "@weekly"
  concurrencyPolicy: Forbid
  startingDeadlineSeconds: 300
  jobTemplate:
    spec:
      template:
        spec:
          hostname: k
          restartPolicy: Never
          containers:
            - name: restic
              image: ghcr.io/janw/restic:latest
              imagePullPolicy: Always
              env:
                - name: RESTIC_REPOSITORY
                  value: b2:my-backblaze-b2-bucket:k
                - name: HEALTHCHECK_URL
                  value: https://hc-ping.com/deadbeef-1234-1234-1234-123456789012
                - name: RESTIC_JOB_ARGS
                  value: --verbose

                # These should be put in a Secret resource instead!
                - name: RESTIC_PASSWORD
                  value: "my_super_secret_backups_password"
                - name: B2_ACCOUNT_ID
                  value: "abdc12039812039821098"
                - name: B2_ACCOUNT_KEY
                  value: "my_secret_key"

              volumeMounts:
              - mountPath: /root/.cache/restic
                name: restic-cache
              - mountPath: /data
                name: backup-data
          volumes:
          - name: restic-cache
            hostPath:
              path: /var/restic-cache
          - name: backup-data
            hostPath:
              path: /mnt/data-to-backup
```
