# Task 04 — Component Notes

**Status**: TODO
**Effort**: S
**Phase**: 1
**Depends on**: task-01

## Goal

Create skeleton notes for each deployed K8s component. These start empty but accumulate
knowledge automatically as Claude discovers configuration quirks, resolves issues, and
documents operational procedures.

## Files to Create (via Obsidian MCP)

Each note follows this structure:

```markdown
# <Component Name>

**Version**: (current)
**Namespace**: <namespace>
**Manifests**: `manifests/<component>/`
**Playbook**: `playbooks/kubernetes/<playbook>.yml`

## Configuration Notes
(Claude appends non-obvious config choices and their reasons)

## Known Issues
(Claude appends issues encountered and their resolutions)

## Runbook
(Claude appends operational procedures: install, upgrade, troubleshoot)
```

## Components

| File | Namespace | Manifests | Playbook |
|------|-----------|-----------|---------|
| `Homelab/Components/ArgoCD.md` | argocd | `manifests/argocd/` | `k8s.argocd.up.yml` |
| `Homelab/Components/Longhorn.md` | longhorn-system | `manifests/k8s_cluster/longhorn/` | `k8s.longhorn.yml` |
| `Homelab/Components/MetalLB.md` | metallb-system | `manifests/k8s_cluster/` | `k8s.metallb.yml` |
| `Homelab/Components/cert-manager.md` | cert-manager | `manifests/cert-manager/` | `k8s.cert-manager.yml` |
| `Homelab/Components/Loki-Grafana.md` | monitoring | n/a (Helm chart) | `k8s.logging.yml` |

## Acceptance Criteria

- [ ] All 5 component notes exist in Obsidian
- [ ] Each note has correct namespace, manifests path, and playbook path filled in
- [ ] All three knowledge sections present (Configuration Notes, Known Issues, Runbook)
- [ ] Component notes linked from `Homelab/Index.md`

## Notes

- Loki/Grafana is deployed via Helm chart (loki-stack, version 2.10.2), not raw manifests
- Grafana is accessible on NodePort 30000
- Loki retention: 28 days (672h)
