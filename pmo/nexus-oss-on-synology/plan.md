# Nexus Repository OSS on Synology (zaphod)

## Goal
Self-hosted artifact registry on zaphod for local Docker images, Docker Hub pull-through
cache, Helm charts, and generic artifacts. Clean HTTPS access via OPNsense HAProxy +
internal CA, with full K8s integration via Ansible-managed containerd mirror config.

## Status: TODO

## Tasks (execution order)

| # | Task | Status | Prereqs |
|---|------|--------|---------|
| 1 | [Pre-flight check on zaphod](task-01-preflight.md) | DONE | none |
| 2 | [Deploy Nexus OSS via Portainer](task-02-deploy-portainer.md) | TODO | task-01 |
| 3 | [Initial configuration](task-03-initial-config.md) | TODO | task-02 |
| 4 | [Create repositories](task-04-create-repositories.md) | TODO | task-03 |
| 5 | [OPNsense HAProxy + internal CA + Unbound DNS](task-05-haproxy-tls-dns.md) | TODO | task-04 |
| 6 | [K8s integration (containerd mirror + CA trust)](task-06-k8s-integration.md) | TODO | task-05 |
| 7 | [ArgoCD / Helm integration](task-07-argocd-helm.md) | TODO | task-06 |

## Infrastructure context
- Registry host: zaphod (Synology DSM 7.x)
- Portainer: already running on zaphod
- OPNsense: router with Unbound DNS + HAProxy plugin
- K8s cluster: disasterarea (control plane) + arthur, ford, trillian (workers)
- Ports: 18081 (UI), 18082 (Docker Hub proxy), 18083 (local Docker)

## Tool choice rationale
Nexus Repository OSS chosen over Artifactory CE: fully open source (Apache 2.0), no
registration required, covers all required repo types (Docker, Helm, Go proxy, generic).
See ADR-005 in Obsidian for full decision record.
