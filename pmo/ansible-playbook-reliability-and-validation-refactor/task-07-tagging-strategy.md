# Task 07 — Tagging Strategy

**Status**: TODO
**Effort**: S (Small)
**Phase**: 1 — Foundation
**Dependencies**: Task 01 (linting)

---

## Goal

Define and apply a consistent tag taxonomy to all tasks across all playbooks, enabling selective execution (run only `preflight`, validate a single component, install only packages) without running the full playbook.

---

## Background

Currently no tasks have tags. This means:
- You cannot run only pre-flight checks without all other tasks
- You cannot re-run only the `configure` phase after a settings change
- You cannot skip a component in the full stack run
- There is no way to run validation without running install

Tags are a low-effort, high-value addition that make the playbooks much more flexible in day-to-day operations.

---

## Acceptance Criteria

- [ ] Tag taxonomy is documented in `CLAUDE.md`
- [ ] Every task in every playbook has at least a `component` tag + `phase` tag
- [ ] `--tags preflight` works across all playbooks (runs only pre-flight asserts)
- [ ] `--tags validate` works across all playbooks (runs only validation tasks)
- [ ] `--tags packages` runs only package installation tasks across all playbooks
- [ ] `--tags never` marks destructive/dangerous tasks that must be explicitly requested
- [ ] `ansible-playbook k8s.all.yml --list-tags` shows the full tag taxonomy

---

## Tag Taxonomy

### Phase Tags

| Tag | Description |
|-----|-------------|
| `preflight` | Pre-flight assertions and connectivity checks |
| `install` | Package installation, Helm deploys, manifest applies |
| `configure` | Configuration file writes, service config, sysctl |
| `validate` | Post-deployment health checks and smoke tests |
| `cleanup` | Teardown, reset, removal operations |

### Component Tags

| Tag | Description |
|-----|-------------|
| `common` | Applies to all hosts (packages, sysctl, base config) |
| `k8s` | Core Kubernetes cluster (kubeadm, kubelet, containerd) |
| `metallb` | MetalLB load balancer |
| `cert-manager` | cert-manager TLS |
| `longhorn` | Longhorn distributed storage |
| `logging` | Loki + Grafana logging stack |
| `argocd` | ArgoCD GitOps controller |
| `security` | Security hardening (UFW, SSH, Fail2ban) |
| `users` | User management and SSH keys |
| `system` | System configuration (timezone, locale, NTP) |

### Action Tags

| Tag | Description |
|-----|-------------|
| `packages` | APT package installs |
| `helm` | Helm chart operations |
| `manifests` | kubectl apply operations |
| `config` | Config file writes |
| `service` | Service enable/start/restart |
| `certificate` | TLS certificate operations |

### Scope Tags

| Tag | Description |
|-----|-------------|
| `never` | Destructive operations (kubeadm reset, node drain) — must be explicitly requested with `--tags never` |

---

## Implementation Steps

### 1. Document Taxonomy in `CLAUDE.md`

Add a new `## Tags` section to `CLAUDE.md`:

````markdown
## Tags

All tasks are tagged with a `component` tag and a `phase` tag.

### Common Usage Examples

```bash
# Run only pre-flight checks (no changes)
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.logging.yml --tags preflight

# Validate all components after deployment
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.validate.yml --tags validate

# Install only packages across all nodes
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.up.yml --tags packages

# Re-apply only configuration (no package installs)
ansible-playbook -i inventory.yml playbooks/security_hardening/security_hardening.up.yml --tags configure

# Re-deploy only Helm charts
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml --tags helm

# Run destructive reset tasks (explicit opt-in required)
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.down.yml --tags never,cleanup
```

### Tag Reference

| Category | Tags |
|----------|------|
| Phase | `preflight`, `install`, `configure`, `validate`, `cleanup` |
| Component | `common`, `k8s`, `metallb`, `cert-manager`, `longhorn`, `logging`, `argocd`, `security`, `users`, `system` |
| Action | `packages`, `helm`, `manifests`, `config`, `service`, `certificate` |
| Scope | `never` (destructive — explicit opt-in only) |
````

### 2. Apply Tags to Task Examples

#### System Config tasks (`system_config.up.yml`)

```yaml
- name: Set timezone to {{ system_timezone }}
  community.general.timezone:
    name: "{{ system_timezone }}"
  tags:
    - system
    - configure

- name: Configure NTP servers
  ansible.builtin.template:
    src: timesyncd.conf.j2
    dest: /etc/systemd/timesyncd.conf
  notify: Restart timesyncd
  tags:
    - system
    - configure
    - service
```

#### K8s install tasks (`k8s.up.yml`)

```yaml
- name: Install kubeadm, kubectl, kubelet
  ansible.builtin.apt:
    name:
      - "kubeadm={{ k8s_version }}-*"
      - "kubectl={{ k8s_version }}-*"
      - "kubelet={{ k8s_version }}-*"
    state: present
  tags:
    - k8s
    - install
    - packages

- name: Initialize Kubernetes control plane
  ansible.builtin.command: kubeadm init ...
  tags:
    - k8s
    - install

- name: Reset kubeadm (destructive)
  ansible.builtin.command: kubeadm reset --force
  tags:
    - k8s
    - cleanup
    - never  # only runs with --tags never
```

#### Helm deploy tasks

```yaml
- name: Deploy Longhorn via Helm
  ansible.builtin.command: helm upgrade --install longhorn ...
  tags:
    - longhorn
    - install
    - helm
```

#### Validation tasks

```yaml
- name: Wait for Grafana deployment
  kubernetes.core.k8s_info: ...
  tags:
    - logging
    - validate
```

### 3. Batch Apply Tags to All Playbooks

Work through each playbook file, applying `component` + `phase` tags to every task. Recommended approach:
1. Open each playbook
2. For each task, determine its component and phase
3. Add `tags:` block using YAML list format
4. Verify with `ansible-playbook <playbook> --list-tasks`

### 4. Verify Tag Listing

```bash
# Should show all defined tags
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml --list-tags

# Should show tasks that would run
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml \
  --tags logging --list-tasks
```

---

## Verification

```bash
# Pre-flight only — no state changes
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.cert-manager.yml \
  --tags preflight
# Expected: only assert tasks run, playbook exits 0

# Validate only — no installs
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.validate.yml \
  --tags validate
# Expected: only validation tasks run

# Packages only — lists package install tasks
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.up.yml \
  --tags packages --list-tasks
# Expected: only apt install tasks listed

# Never tasks not included in normal run
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.down.yml \
  --list-tasks
# Expected: kubeadm reset NOT in list

# Never tasks included when explicitly requested
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.down.yml \
  --tags never --list-tasks
# Expected: kubeadm reset in list
```

---

## Subtasks

- [ ] Write tag taxonomy section in `CLAUDE.md`
- [ ] Apply tags to all tasks in `playbooks/kubernetes/k8s.up.yml`
- [ ] Apply tags to all tasks in `playbooks/kubernetes/k8s.cert-manager.yml`
- [ ] Apply tags to all tasks in `playbooks/kubernetes/k8s.metallb.yml`
- [ ] Apply tags to all tasks in `playbooks/kubernetes/k8s.longhorn.yml`
- [ ] Apply tags to all tasks in `playbooks/kubernetes/k8s.logging.yml`
- [ ] Apply tags to all tasks in `playbooks/kubernetes/k8s.argocd.up.yml`
- [ ] Apply tags to all tasks in `playbooks/kubernetes/k8s.down.yml` (mark destructive with `never`)
- [ ] Apply tags to all tasks in system, security, user_management playbooks
- [ ] Apply tags to all tasks in top-level playbooks (prepare, apt_upgrade, etc.)
- [ ] Verify `--list-tags` shows expected taxonomy
- [ ] Verify `--tags preflight` and `--tags validate` work correctly
