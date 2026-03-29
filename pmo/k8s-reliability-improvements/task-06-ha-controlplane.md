# Task 06 — HA Control Plane (3 nodes, mixed role)

## Status: BACKLOG
## Priority: LOW — etcd backup (task-02) provides adequate protection for homelab use
## Prereqs: task-01 (cluster at 1.32.x before reconfiguring control plane)

## Summary
Convert the single control plane to a 3-node HA setup using mixed-role nodes
(CP + worker on arthur and ford). No new hardware required.
etcd replication across 3 nodes provides automatic failover — if one CP node dies,
the cluster continues operating without manual intervention.

## Proposed topology

| Node | Role | Workloads |
|------|------|-----------|
| disasterarea | CP only (tainted) | No |
| arthur | CP + worker (untainted) | Yes |
| ford | CP + worker (untainted) | Yes |
| trillian | Worker only | Yes |

Result: 3 CP nodes (etcd quorum survives 1 failure) + 3 effective workers.

## What's needed

### 1. Virtual IP for kube-apiserver load balancing
- keepalived on the 3 CP nodes with a shared VIP (e.g. 10.1.1.5)
- haproxy on each CP node forwarding VIP:6443 → all 3 apiservers
- kubeadm init must use `--control-plane-endpoint` pointing to the VIP

### 2. Cluster rebuild (destructive)
Adding CP nodes to an existing single-CP cluster is possible but risky.
Recommended approach: full cluster rebuild using k8s.down.yml + k8s.up.yml
with updated kubeadm config.

Alternative: `kubeadm join --control-plane` can add CP nodes to an existing
cluster if it was initialized with `--control-plane-endpoint`. The current
cluster was NOT (uses direct node IP), so a rebuild is needed.

### 3. Resource overhead per mixed-role node
etcd: ~200–500 MB RAM | kube-apiserver: ~300–500 MB RAM | kube-scheduler/controller-manager: ~100 MB each
Total CP overhead per node: ~700 MB–1.1 GB RAM.
Acceptable for mini PCs with 8+ GB RAM.

## Files to create
- `playbooks/kubernetes/keepalived-haproxy.up.yml`
- `playbooks/kubernetes/keepalived-haproxy.down.yml`
- Update `playbooks/kubernetes/k8s.up.yml` — add `--control-plane-endpoint` to kubeadm init
- Update `playbooks/kubernetes/k8s_vars.yml` — add `control_plane_vip` variable

## Verification
- `kubectl get nodes` shows all 4 nodes Ready with correct roles
- Shut down disasterarea → `kubectl get nodes` still works via VIP
- `kubectl get pods -A` — no disruption to running workloads during failover

## Potential subtasks
- [ ] Decide on VIP address (e.g. 10.1.1.5 — outside MetalLB pool 10.1.1.10–250)
- [ ] Write keepalived-haproxy.up.yml
- [ ] Update k8s.up.yml for --control-plane-endpoint
- [ ] Plan cluster rebuild window (requires full downtime)
- [ ] Document join procedure for adding 2nd and 3rd CP node
- [ ] Test failover by powering off disasterarea
