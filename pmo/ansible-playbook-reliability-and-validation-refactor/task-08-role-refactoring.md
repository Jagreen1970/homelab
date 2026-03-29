# Task 08 — Role Refactoring

**Status**: TODO
**Effort**: XL (Extra Large)
**Phase**: 4 — Refactor
**Dependencies**: Task 01 (linting), Task 04 (error handling), Task 05 (idempotency), Task 07 (tagging)

---

## Goal

Extract common, repeated logic from inline playbooks into reusable Ansible roles. Refactor playbooks to become thin orchestrators (< 50 lines) that compose roles. This eliminates copy-paste, enforces consistency, and makes the codebase easier to test.

---

## Background

Currently all automation logic lives inline in playbooks. Patterns like kernel module loading, containerd installation, and Helm chart deployment are duplicated or entangled. The `.ansible/roles/` directory exists but is empty. Role extraction enables:

- A single place to fix a pattern (not N playbooks)
- Molecule-based unit testing (Task 10)
- Clean separation of "what to do" (role) from "when and where" (playbook)
- `defaults/main.yml` as a self-documenting interface for each role

**Do this task last in the sequence** — roles are easiest to extract once the code is already clean (linting passes, error handling is sound, tasks are idempotent).

---

## Acceptance Criteria

- [ ] `roles/common/` exists — handles base packages, kernel modules, sysctl, NTP
- [ ] `roles/k8s_node/` exists — handles containerd and kubeadm/kubectl/kubelet installation
- [ ] `roles/k8s_addons/` exists — handles the Helm deploy + wait pattern as a reusable role
- [ ] Each role has `defaults/main.yml`, `tasks/main.yml`, `handlers/main.yml`, `meta/main.yml`
- [ ] Each role has a `README.md` documenting its variables and usage
- [ ] Playbooks that use extracted roles are ≤ 50 lines each (orchestration only)
- [ ] `ansible-playbook k8s.all.yml` succeeds end-to-end after refactor

---

## Roles to Create

### `roles/common/`

**Extracted from**: `k8s.up.yml` (host preparation tasks)

**Responsibilities**:
- Install base packages (`htop`, `curl`, `apt-transport-https`, etc.)
- Load kernel modules (`overlay`, `br_netfilter`)
- Apply sysctl settings (`net.bridge.bridge-nf-call-iptables`, `net.ipv4.ip_forward`)
- Disable swap
- Set NTP (delegate or reference `system_config` playbook)

**`roles/common/defaults/main.yml`**:
```yaml
---
common_packages:
  - curl
  - apt-transport-https
  - ca-certificates
  - gnupg
  - htop

common_kernel_modules:
  - overlay
  - br_netfilter

common_sysctl_settings:
  net.bridge.bridge-nf-call-iptables: 1
  net.bridge.bridge-nf-call-ip6tables: 1
  net.ipv4.ip_forward: 1
```

**`roles/common/tasks/main.yml`** (structure):
```yaml
---
- name: Install base packages
  ansible.builtin.import_tasks: packages.yml
  tags: [common, install, packages]

- name: Load kernel modules
  ansible.builtin.import_tasks: kernel_modules.yml
  tags: [common, configure]

- name: Apply sysctl settings
  ansible.builtin.import_tasks: sysctl.yml
  tags: [common, configure]

- name: Disable swap
  ansible.builtin.import_tasks: swap.yml
  tags: [common, configure]
```

---

### `roles/k8s_node/`

**Extracted from**: `k8s.up.yml` (containerd + K8s package installation)

**Responsibilities**:
- Add Docker/containerd APT repository
- Install and configure containerd
- Add Kubernetes APT repository
- Install `kubeadm`, `kubectl`, `kubelet` at pinned version
- Enable and start `kubelet`

**`roles/k8s_node/defaults/main.yml`**:
```yaml
---
k8s_version: "1.28.0"
k8s_apt_key_url: "https://pkgs.k8s.io/core:/stable:/v{{ k8s_version | regex_replace('\\.(\\d+)$', '') }}/deb/Release.key"
k8s_apt_repo: "https://pkgs.k8s.io/core:/stable:/v{{ k8s_version | regex_replace('\\.(\\d+)$', '') }}/deb/"

containerd_config_template: containerd_config.toml.j2
```

**`roles/k8s_node/handlers/main.yml`**:
```yaml
---
- name: Restart containerd
  ansible.builtin.service:
    name: containerd
    state: restarted
  listen: Restart containerd
```

---

### `roles/k8s_addons/`

**Extracted from**: `k8s.longhorn.yml`, `k8s.logging.yml`, `k8s.argocd.up.yml`

**Responsibilities**:
- Add a Helm repository
- Deploy a Helm chart with `upgrade --install`
- Wait for the deployment to be Available
- Optionally run post-deploy verification

**`roles/k8s_addons/defaults/main.yml`**:
```yaml
---
k8s_addon_name: ""               # e.g., "longhorn"
k8s_addon_namespace: ""          # e.g., "longhorn-system"
k8s_addon_chart: ""              # e.g., "longhorn/longhorn"
k8s_addon_version: ""            # e.g., "1.4.1"
k8s_addon_values_file: ""        # path to values.yaml
k8s_addon_wait_deployment: ""    # deployment name to wait for
k8s_addon_wait_timeout: 300
k8s_addon_create_namespace: true
```

**`roles/k8s_addons/tasks/main.yml`**:
```yaml
---
- name: Add Helm repository for {{ k8s_addon_name }}
  ansible.builtin.command: >
    helm repo add {{ k8s_addon_name }} {{ k8s_addon_repo_url }}
  register: helm_repo_add
  changed_when: "'already exists' not in helm_repo_add.stdout"
  tags: [helm, install]

- name: Update Helm repositories
  ansible.builtin.command: helm repo update
  changed_when: true
  tags: [helm, install]

- name: Deploy {{ k8s_addon_name }} via Helm
  block:
    - name: Install or upgrade {{ k8s_addon_name }}
      ansible.builtin.command: >
        helm upgrade --install {{ k8s_addon_name }} {{ k8s_addon_chart }}
        --namespace {{ k8s_addon_namespace }}
        {% if k8s_addon_create_namespace %}--create-namespace{% endif %}
        --version {{ k8s_addon_version }}
        {% if k8s_addon_values_file %}--values {{ k8s_addon_values_file }}{% endif %}
        --wait --timeout {{ k8s_addon_wait_timeout }}s
      register: helm_deploy
      changed_when: >
        'has been upgraded' in helm_deploy.stdout or
        'has been installed' in helm_deploy.stdout
      tags: [helm, install]
  rescue:
    - name: Show Helm deploy failure
      ansible.builtin.debug:
        msg: "Helm deploy failed for {{ k8s_addon_name }}: {{ helm_deploy.stderr }}"
    - ansible.builtin.fail:
        msg: "{{ k8s_addon_name }} Helm deployment failed. See above for details."

- name: Wait for {{ k8s_addon_name }} deployment to be Available
  kubernetes.core.k8s_info:
    kind: Deployment
    name: "{{ k8s_addon_wait_deployment }}"
    namespace: "{{ k8s_addon_namespace }}"
    wait: true
    wait_timeout: "{{ k8s_addon_wait_timeout }}"
    wait_condition:
      type: Available
      status: "True"
  when: k8s_addon_wait_deployment | length > 0
  tags: [validate]
```

---

## Playbook Refactor Example

**Before** (`k8s.longhorn.yml` — ~200 lines inline):
```yaml
---
- name: Deploy Longhorn distributed storage
  hosts: k8s_control_plane
  vars_files:
    - k8s_vars.yml
  tasks:
    - name: Install open-iscsi on workers
      # 20 lines...
    - name: Add Longhorn helm repo
      # 10 lines...
    - name: Deploy Longhorn via Helm
      # 30 lines with error handling...
    # ... etc
```

**After** (`k8s.longhorn.yml` — ~40 lines, orchestration only):
```yaml
---
- name: Pre-flight checks
  hosts: k8s_control_plane
  gather_facts: true
  tasks:
    - ansible.builtin.import_tasks: includes/preflight_k8s.yml

- name: Prepare worker nodes for Longhorn
  hosts: k8s_workers
  gather_facts: true
  tasks:
    - name: Install open-iscsi
      ansible.builtin.apt:
        name: open-iscsi
        state: present
      tags: [longhorn, install, packages]

- name: Deploy Longhorn
  hosts: k8s_control_plane
  gather_facts: true
  roles:
    - role: k8s_addons
      vars:
        k8s_addon_name: longhorn
        k8s_addon_namespace: longhorn-system
        k8s_addon_chart: longhorn/longhorn
        k8s_addon_version: "{{ longhorn_version }}"
        k8s_addon_repo_url: "https://charts.longhorn.io"
        k8s_addon_values_file: "{{ playbook_dir }}/../../manifests/k8s_cluster/longhorn/longhorn-values.yaml"
        k8s_addon_wait_deployment: longhorn-ui
        k8s_addon_wait_timeout: 300
```

---

## Implementation Steps

1. **Create roles directory structure**:
   ```bash
   mkdir -p roles/{common,k8s_node,k8s_addons}/{tasks,defaults,handlers,meta}
   ```

2. **Extract `roles/common/`** from `k8s.up.yml`:
   - Tasks: disable swap, kernel modules, sysctl, base packages
   - Handlers: (none — sysctl reload is typically inline)
   - Defaults: package list, kernel module list, sysctl map

3. **Extract `roles/k8s_node/`** from `k8s.up.yml`:
   - Tasks: containerd install + config, K8s repo setup, kubeadm/kubectl/kubelet install
   - Handlers: restart containerd
   - Defaults: k8s_version, repo URLs
   - Templates: `containerd_config.toml.j2`

4. **Create `roles/k8s_addons/`** as new generic role:
   - Tasks: helm repo add, helm upgrade --install, k8s_info wait
   - Defaults: all addon parameters as documented above

5. **Refactor playbooks** to use roles (start with smallest — `k8s.cert-manager.yml` or `k8s.metallb.yml`):
   - Remove inline task logic that is now in roles
   - Replace with `roles:` section and variable overrides
   - Keep only orchestration logic (play targeting, variable passing)

6. **Write `meta/main.yml`** for each role:
   ```yaml
   # roles/common/meta/main.yml
   ---
   galaxy_info:
     author: homelab
     description: Base host configuration for K8s nodes
     min_ansible_version: "2.14"
   dependencies: []
   ```

7. **Write `README.md`** for each role documenting variables and example usage.

8. **Run end-to-end test**: `ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml`

---

## Verification

```bash
# Roles are discoverable
ansible -i inventory.yml all -m ansible.builtin.include_role -a "name=common" --check

# Full stack still works
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml --check

# Playbook line counts are under 50 (after refactor)
wc -l playbooks/kubernetes/k8s.longhorn.yml playbooks/kubernetes/k8s.logging.yml
```

---

## Subtasks

- [ ] Create `roles/` directory structure (common, k8s_node, k8s_addons)
- [ ] Write `roles/common/` (defaults, tasks, meta, README)
- [ ] Write `roles/k8s_node/` (defaults, tasks, handlers, meta, README)
- [ ] Write `roles/k8s_addons/` (defaults, tasks, meta, README)
- [ ] Refactor `k8s.up.yml` to use `roles/common/` and `roles/k8s_node/`
- [ ] Refactor `k8s.longhorn.yml` to use `roles/k8s_addons/`
- [ ] Refactor `k8s.logging.yml` to use `roles/k8s_addons/`
- [ ] Refactor `k8s.argocd.up.yml` to use `roles/k8s_addons/`
- [ ] Verify playbook line counts are ≤ 50
- [ ] Verify `make lint` passes after refactor
- [ ] End-to-end test: `ansible-playbook k8s.all.yml --check`
