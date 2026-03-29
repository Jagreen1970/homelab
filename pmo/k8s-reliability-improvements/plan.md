# Homelab K8s Reliability Improvements

## Goal
Bring the cluster to a reliable, observable state: up-to-date K8s, automated backups,
disruption protection, and metrics+alerting.

## Status: IN PLANNING

## Tasks (execution order)

| # | Task | Status | Prereqs |
|---|------|--------|---------|
| 1 | [K8s Upgrade 1.28→1.32](task-01-k8s-upgrade.md) | TODO | none |
| 2 | [etcd Backup](task-02-etcd-backup.md) | TODO | task-01 |
| 3 | [Longhorn Backups](task-03-longhorn-backup.md) | TODO | task-01 |
| 4 | [Pod Disruption Budgets](task-04-pod-disruption-budgets.md) | TODO | task-01 |
| 5 | [Prometheus + Alerting](task-05-prometheus-alerting.md) | TODO | task-01, task-03 |
| 6 | [HA Control Plane](task-06-ha-controlplane.md) | BACKLOG | task-01 |

## Cluster info
- Control plane: disasterarea (1 node — HA deferred to task-06)
- Workers: arthur, ford, trillian
- NAS: zaphod (Synology) — NFS at zaphod:/volume1/kubernetes
- Current K8s: 1.28.0 | Target: 1.32.x
