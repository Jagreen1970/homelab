# Task 02 — etcd Backup

## Status: TODO
## Priority: HIGH — no recovery possible if control plane is lost
## Prereqs: task-01 (stable upgraded cluster)

## Summary
Automated daily etcd snapshots stored on Synology NAS via NFS.
Two delivery mechanisms: Ansible playbook (manual/ad-hoc) + K8s CronJob (automated).

## Files to create
- `playbooks/kubernetes/k8s.etcd-backup.yml` — Ansible playbook for manual snapshots
- `manifests/k8s_cluster/etcd/etcd-backup-pv.yaml` — PersistentVolume on NFS
- `manifests/k8s_cluster/etcd/etcd-backup-pvc.yaml` — PersistentVolumeClaim
- `manifests/k8s_cluster/etcd/etcd-backup-cronjob.yaml` — K8s CronJob (daily 2am)
- `playbooks/kubernetes/ETCD_RESTORE.md` — restore procedure documentation

## NFS setup required on Synology
- Create share: /volume1/kubernetes/etcd-backups
- Grant NFS access to disasterarea IP with no_root_squash

## Ansible playbook logic
- Run on: disasterarea (control plane)
- `etcdctl snapshot save /tmp/etcd-{{ ansible_date_time.epoch }}.db`
  with `--cacert/--cert/--key` pointing to `/etc/kubernetes/pki/etcd/`
- Verify with: `etcdctl snapshot status`
- Copy to NFS mount point
- Prune snapshots older than 7 days

## CronJob spec
- Namespace: kube-system
- Schedule: `"0 2 * * *"`
- Image: bitnami/etcd (includes etcdctl)
- NodeSelector: `node-role.kubernetes.io/control-plane: ""`
- Tolerations: control-plane taint
- HostPath mounts: `/etc/kubernetes/pki/etcd` (read-only)
- NFS volume for backup destination

## Verification
- Manual run of playbook → snapshot file appears on NAS
- `etcdctl snapshot status <file>` exits 0
- After 24h: CronJob pod shows Completed in `kubectl get pods -n kube-system`

## Potential subtasks
- [ ] Create NFS export on Synology for etcd-backups
- [ ] Write k8s.etcd-backup.yml
- [ ] Write and apply PV/PVC manifests
- [ ] Write and apply CronJob manifest
- [ ] Write ETCD_RESTORE.md with step-by-step restore procedure
- [ ] Test restore on a non-production snapshot
