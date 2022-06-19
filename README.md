# Ansible Role: seaweedfs

Deploy a SeaweedFS object storage cluster.

## Inventory

The role will deploy SeaweedFS to all nodes, while doing so it will check the seaweedfs_masters, seaweedfs_filers and seaweedfs_volumes groups to choose which if any functionality should be installed along side the SeaweedFS binary.

If the group seaweedfs_meta_backups is defined then it is checked for hosts which should run the filer.meta.backup service.

## Filers

### Filers
`seaweedfs_filer_toml` can be defined to point to a filer.toml file which is then applied to filers.

### Meta Backup
filer meta backup service requires `seaweedfs_backup_filer_toml` be defined and pointing to a valid filer.toml file describing the backup filer.

## S3

If `seaweedfs_s3_json` is defined then the file it points to is copied and used as the config for the S3 interface.
