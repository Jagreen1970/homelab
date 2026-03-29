# Task 03 — Longhorn Volume Backups

## Status: TODO
## Priority: HIGH — volumes currently have no off-node backup
## Prereqs: task-01

## Summary
Enable Longhorn's built-in NFS backup target pointing to Synology NAS.
Add a RecurringJob for automated daily backups with 7-day retention.

## Files to modify
- `manifests/k8s_cluster/longhorn/longhorn-values.yaml`
  - Set: `backupTarget: "nfs://zaphod:/volume1/kubernetes/longhorn-backups"`
  - Longhorn handles NFS mounting natively — no extra provisioner needed

## Files to create
- `manifests/k8s_cluster/longhorn/longhorn-backup-recurringjob.yaml`
  - Kind: RecurringJob (longhorn.io/v1beta2)
  - Groups: default (applies to all volumes in the default group)
  - Tasks: snapshot (daily, retain 7) + backup (daily, retain 7)
  - Schedule: `"0 1 * * *"`
  - Concurrency: 2

## NFS setup required on Synology
- Create share: /volume1/kubernetes/longhorn-backups
- Grant NFS access to all cluster node IPs with no_root_squash

## Playbook change
- `playbooks/kubernetes/k8s.longhorn.yml`: ensure values file is re-applied
  (helm upgrade with updated values)

## Verification
- Longhorn UI → Settings → Backup Target shows `nfs://zaphod:/volume1/kubernetes/longhorn-backups`
- Longhorn UI → Backup Target Health: Healthy
- Trigger manual backup on one volume → appears in Backup list
- After 24h: scheduled backup appears automatically

## Potential subtasks
- [ ] Create NFS export on Synology for longhorn-backups
- [ ] Update longhorn-values.yaml backupTarget
- [ ] Run helm upgrade via k8s.longhorn.yml
- [ ] Write and apply RecurringJob manifest
- [ ] Verify backup target health in Longhorn UI
