# Task 02 — Initial ADRs

**Status**: TODO
**Effort**: M
**Phase**: 1
**Depends on**: task-01

## Goal

Capture the three most significant architectural decisions already made in the project as
ADR notes in Obsidian. These represent permanent rationale that must survive beyond any
single Claude session.

## ADRs to Write

### ADR-001 — Flannel as CNI Plugin
**File**: `Homelab/Architecture/Decisions/ADR-001-flannel-cni.md`

Key points to cover:
- **Context**: Needed a CNI plugin for pod-to-pod networking across 4 nodes
- **Decision**: Flannel (VXLAN mode), pod CIDR 10.244.0.0/16
- **Alternatives considered**: Calico (more complex, BGP overkill for homelab), Cilium (eBPF
  requires newer kernels, adds complexity)
- **Consequences**: Simple overlay network, no network policy enforcement, sufficient for
  homelab workloads

**References**:
- `playbooks/kubernetes/k8s_vars.yml` (`cni_plugin: flannel`, `pod_network_cidr: 10.244.0.0/16`)
- `playbooks/kubernetes/k8s.up.yml`

---

### ADR-002 — Longhorn for Distributed Storage
**File**: `Homelab/Architecture/Decisions/ADR-002-longhorn-storage.md`

Key points to cover:
- **Context**: Needed persistent storage that survives single-node failure
- **Decision**: Longhorn with 3-replica volumes + NFS backup to Synology NAS (zaphod)
- **Alternatives considered**: Pure NFS (single point of failure), Rook/Ceph (heavyweight for
  4-node cluster), local-path provisioner (no HA)
- **Consequences**: Distributed replication across nodes, volume snapshots, backup to NAS;
  requires `iscsid` on all nodes; consumes additional disk I/O

**References**:
- `playbooks/kubernetes/k8s.longhorn.yml`
- `manifests/k8s_cluster/longhorn/`

---

### ADR-003 — ArgoCD for GitOps
**File**: `Homelab/Architecture/Decisions/ADR-003-argocd-gitops.md`

Key points to cover:
- **Context**: Needed a repeatable, auditable way to deploy and manage K8s applications
- **Decision**: ArgoCD in pull-model GitOps — applications declared in Git, synced by ArgoCD
- **Alternatives considered**: Flux (less UI, similar capability), plain kubectl applies
  (no drift detection, no audit trail), Helm-only (no continuous reconciliation)
- **Consequences**: All app state tracked in Git, automatic drift detection, good web UI;
  requires ArgoCD to be bootstrapped manually before it can manage itself

**References**:
- `playbooks/kubernetes/k8s.argocd.up.yml`
- `manifests/argocd/`

## Acceptance Criteria

- [ ] ADR-001 created with Status: Accepted
- [ ] ADR-002 created with Status: Accepted
- [ ] ADR-003 created with Status: Accepted
- [ ] All three ADRs linked from `Homelab/Architecture/Decisions/` (discoverable via list)
