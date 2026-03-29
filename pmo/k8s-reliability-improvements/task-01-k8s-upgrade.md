# Task 01 — Kubernetes Version Upgrade (1.28 → 1.32)

## Status: TODO
## Priority: HIGH — run first (EOL version has security risk)
## Prereqs: none

## Summary
Incrementally upgrade from 1.28.0 to 1.32.x, one minor version at a time.
Each pass: upgrade control plane, then drain/upgrade/uncordon each worker.

## Files to create
- `playbooks/kubernetes/k8s.upgrade.yml`

## Files to modify
- `playbooks/kubernetes/k8s_vars.yml` — add `k8s_target_version` variable

## Steps
1. Add `k8s_target_version: 1.29.0` to k8s_vars.yml
2. Run `ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.upgrade.yml -K`
3. Verify: `kubectl get nodes` shows v1.29.x for all nodes
4. Repeat steps 1–3 for 1.30.0, 1.31.0, 1.32.x

## Playbook logic (per run)
- Upgrade kubeadm on disasterarea to target version
- Run `kubeadm upgrade plan` (sanity check)
- Run `kubeadm upgrade apply v{{ k8s_target_version }}`
- Upgrade kubelet + kubectl on disasterarea, restart kubelet
- For each worker sequentially:
  - kubectl drain (--ignore-daemonsets --delete-emptydir-data)
  - Upgrade kubeadm, kubelet, kubectl; restart kubelet
  - kubectl uncordon
- Assert all nodes Ready at target version

## Verification
- `kubectl get nodes -o wide` — all nodes at target version, all Ready
- `kubectl get pods -A` — no pods stuck in Terminating/Pending after each pass

## Potential subtasks
- [ ] Write k8s.upgrade.yml
- [ ] Test dry-run with --check on 1.29 pass
- [ ] Validate Longhorn, ArgoCD, logging stack all healthy post-upgrade
- [ ] Update k8s_vars.yml k8s_version to final version after all passes
