# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- Run a playbook: `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml`
- Run with sudo prompt: `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml -K`
- Syntax check: `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml --syntax-check`
- Check mode (dry run): `ansible-playbook -i inventory.yml playbooks/<playbook_name>.yml --check`
- Run on specific host: `ansible-playbook -i inventory.yml -l <hostname> playbooks/<playbook_name>.yml`
- Lint playbooks: `ansible-lint playbooks/*.yml`
- Validate YAML: `yamllint playbooks/*.yml`
- Ad-hoc module test: `ansible -i inventory.yml <hostname> -m <module_name> -a "<module_arguments>"`

## Architecture Overview

This is an Ansible-based homelab automating a 4-node Kubernetes cluster of mini PCs (hostnames: `disasterarea`, `arthur`, `ford`, `trillian`). `disasterarea` is the control plane; the others are workers. A Synology NAS is available as external storage. All nodes run Ubuntu 24.04 (kernel 6.8.0-106-generic).

### Node Hardware

| Host | IP | CPU | RAM | Disk | NIC |
|---|---|---|---|---|---|
| disasterarea | 192.168.1.166 | Intel N100 (4 cores) | 15.4 GB | ~98 GB | eth only |
| arthur | 192.168.1.24 | Intel N100 (4 cores) | 15.4 GB | ~467 GB | eth + WiFi |
| ford | 192.168.1.76 | Intel Celeron N5105 (4 cores) | 15.5 GB | ~467 GB | eth + WiFi |
| trillian | 192.168.1.67 | Intel Celeron N5105 (4 cores) | 11.5 GB | ~233 GB | eth + WiFi |

Total usable capacity: 16 CPU cores, ~57.8 GB RAM, ~1267 GB disk.

Note: `disasterarea` has significantly less storage than the worker nodes and is eth-only. Docker is in the `docker_hosts` inventory group for all four nodes but is currently only installed on the three worker nodes.

### Inventory Groups

- `k8s_control_plane`: disasterarea
- `k8s_workers`: arthur, ford, trillian
- `docker_hosts`: all four nodes (Docker installed on workers only)

### Playbook Structure

Top-level playbooks in `playbooks/` handle system-wide concerns (user prep, upgrades, reboots, resource reporting). Domain-specific work lives in subdirectories, each with `*.up.yml` / `*.down.yml` pairs for reversible operations:

| Directory | Purpose |
|---|---|
| `kubernetes/` | Full K8s lifecycle — cluster init, storage, logging, certs, load balancer, GitOps |
| `user_management/` | User accounts and SSH keys |
| `security_hardening/` | SSH config, firewall |
| `system_config/` | Hostname, timezone, locale |

**K8s orchestration**: `playbooks/kubernetes/k8s.all.yml` imports seven playbooks in sequence for a full cluster setup. Individual components (Longhorn, MetalLB, cert-manager, Loki/Grafana, ArgoCD) each have their own playbook.

### Variables

- `playbooks/admin_vars.yml` — admin group and user list (shared across all playbooks)
- `playbooks/kubernetes/k8s_vars.yml` — K8s version (1.28.0), pod CIDR, CNI (flannel), component versions
- `playbooks/security_hardening/security_vars.yml`, `playbooks/system_config/system_vars.yml` — domain-specific config

### Manifests

`manifests/` contains raw Kubernetes YAML organized by component. Per-node directories (`disasterarea/`, `arthur/`, etc.) hold node-specific configs. Application manifests (ArgoCD, cert-manager, GitLab runner, Longhorn, MetalLB, monitoring, postgres, etc.) each have their own subdirectory.

## Style Guidelines

- **Naming**: snake_case for variables, tasks, and file names
- **YAML**: 2-space indentation
- **Module names**: Always fully qualified (e.g., `ansible.builtin.copy`, `ansible.posix.authorized_key`, `community.general.sudoers`)
- **Variables**: Use `*_vars.yml` files for centralized config; reference with `{{ variable_name }}`
- **Paired playbooks**: Use `*.up.yml` / `*.down.yml` for operations that need a teardown counterpart
- **Error handling**: Use `failed_when` for custom failure conditions

## Obsidian Documentation

At the start of every session, read `Homelab/Index.md` from Obsidian using the obsidian
MCP tool. If the task relates to a workstream, also read the relevant
`Homelab/Workstreams/` note. Announce briefly what context was loaded.

Proactively write to Obsidian without waiting to be asked:

- **ADR**: When an architectural decision is made (tool choice, approach, version pin,
  design trade-off), create a new ADR note in `Homelab/Architecture/Decisions/` using the
  template at `Homelab/Architecture/Decisions/ADR-template.md`. Use sequential numbering
  (ADR-004, ADR-005, ...). Append the ADR link to the relevant workstream note under
  "Decisions Made".

- **Workstream progress**: When a task from `pmo/` is completed, patch the corresponding
  checkbox in the matching `Homelab/Workstreams/` note and append a dated entry to the
  "Progress Log" section: `**YYYY-MM-DD**: Completed Task NN — <brief description>.`

- **Component knowledge**: When a non-obvious discovery is made about a deployed component
  (config quirk, required pre-condition, issue + resolution, operational procedure), append
  it to the relevant `Homelab/Components/` note under the appropriate section
  (Configuration Notes / Known Issues / Runbook).
