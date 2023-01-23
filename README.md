# Ansible Role: seaweedfs

Deploy a SeaweedFS object storage cluster.

## Inventory

The role will deploy SeaweedFS to all nodes, while doing so it will check the seaweedfs_masters, seaweedfs_filers, seaweedfs_volumes and seaweedfs_proxmox groups to choose which if any functionality should be installed along side the SeaweedFS binary.

If the group seaweedfs_meta_backups is defined then it is checked for hosts which should run the filer.meta.backup service.

Hosts in the seaweedfs_proxmox group will have a custom storage plugin installed however this role does not configure the storage.

## Filers

### Filers
`seaweedfs_filer_toml` is the filer.toml which is applied to filers.

### Meta Backup
filer meta backup service requires `seaweedfs_backup_filer_toml` be defined as a valid filer.toml configuration for the backup filer.

### S3

If `seaweedfs_s3_json` is defined then it is used as the config for the S3 interface.

## Proxmox Storage plugin

Storage can be defined with:

```bash
pvesm add seaweedfs swfs --shared 1 --filer 192.168.0.10:8888,192.168.0.11:8888 --filerpath /proxmox1 \
  --disk ssd --nodes node1,node2 --content images,vztmpl,iso,backup,snippets,rootdir \
  --collection proxmoxcollection --cacheCapacityMB 4096 --chunkSizeLimitMB 2 \
  --replication 000
```

Note: `--shared 1` must be set to allow migration of VMs.

It the storage that has been defined can be removed with:

```bash
pvesm remove swfs
```
