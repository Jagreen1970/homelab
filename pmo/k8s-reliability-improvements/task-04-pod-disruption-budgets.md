# Task 04 — Pod Disruption Budgets

## Status: TODO
## Priority: MEDIUM — prevents accidental outages during node maintenance
## Prereqs: task-01

## Summary
Add PodDisruptionBudget resources for all critical single-replica and
distributed components so node drains require intentional force.

## Files to create
- `manifests/k8s_cluster/pdb/longhorn-pdb.yaml`
- `manifests/k8s_cluster/pdb/metallb-pdb.yaml`
- `manifests/k8s_cluster/pdb/logging-pdb.yaml`
- `manifests/k8s_cluster/pdb/argocd-pdb.yaml`
- `manifests/k8s_cluster/pdb/nfs-provisioner-pdb.yaml`

## New playbook
- `playbooks/kubernetes/k8s.pdb.yml`
  - Applies all manifests in manifests/k8s_cluster/pdb/
  - Idempotent (kubectl apply)

## PDB specs

| Component | Namespace | Selector | minAvailable |
|-----------|-----------|----------|--------------|
| longhorn-manager | longhorn-system | app=longhorn-manager | 1 |
| metallb-controller | metallb-system | app=metallb,component=controller | 1 |
| loki | monitoring | app=loki | 1 |
| grafana | monitoring | app.kubernetes.io/name=grafana | 1 |
| argocd-server | argocd | app.kubernetes.io/name=argocd-server | 1 |
| argocd-application-controller | argocd | app.kubernetes.io/name=argocd-application-controller | 1 |
| nfs-provisioner | default | app=nfs-subdir-external-provisioner | 1 |

Note: NFS provisioner has only 1 replica — its PDB will block drains.
This is intentional: forces operator to use --disable-eviction when draining,
ensuring they are aware the provisioner will be briefly unavailable.

## Verification
- `kubectl get pdb -A` — lists all PDBs with ALLOWED DISRUPTIONS column
- Attempt `kubectl drain <worker-node> --ignore-daemonsets` →
  drain should pause on PDB-protected pods and display a blocking message

## Potential subtasks
- [ ] Write all 5 PDB manifest files
- [ ] Write k8s.pdb.yml playbook
- [ ] Run playbook and verify with `kubectl get pdb -A`
- [ ] Test drain behavior on one worker node
