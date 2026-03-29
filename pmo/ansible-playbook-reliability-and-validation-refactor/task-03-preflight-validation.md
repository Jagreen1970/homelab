# Task 03 — Pre-flight Validation

**Status**: TODO
**Effort**: M (Medium)
**Phase**: 2 — Hardening
**Dependencies**: Task 01 (linting), Task 02 (group_vars)

---

## Goal

Add `ansible.builtin.assert`-based pre-flight checks to every playbook so invalid inputs, missing prerequisites, and unhealthy cluster state are caught **before** any state changes are made.

---

## Background

Currently playbooks start executing immediately without validating their preconditions. A missing variable, an unreachable host, or a cluster in a degraded state will cause failures mid-run — sometimes after making partial changes that leave the system in an unknown state. Pre-flight checks create a clear "gate" phase that fails fast with actionable error messages.

---

## Acceptance Criteria

- [ ] `playbooks/includes/preflight_common.yml` exists with connectivity and disk space checks
- [ ] `playbooks/includes/preflight_k8s.yml` exists with K8s cluster state checks
- [ ] Every top-level playbook begins with an imported pre-flight play
- [ ] Running a playbook with a missing required variable fails immediately with a descriptive `fail_msg`
- [ ] Running a K8s playbook against a cluster with NotReady nodes fails pre-flight
- [ ] Pre-flight tasks are tagged `preflight` for selective execution

---

## Implementation Steps

### 1. Create `playbooks/includes/preflight_common.yml`

```yaml
# playbooks/includes/preflight_common.yml
---
- name: Assert required variables are defined
  ansible.builtin.assert:
    that:
      - admin_group is defined and admin_group | length > 0
    fail_msg: "Required variable 'admin_group' is not defined. Check group_vars/all/main.yml."
  tags: preflight

- name: Check sufficient disk space on all hosts
  ansible.builtin.shell: |
    df --output=avail -BG / | tail -1 | tr -d 'G'
  register: disk_free_gb
  changed_when: false
  tags: preflight

- name: Assert at least 5 GB free on root filesystem
  ansible.builtin.assert:
    that:
      - disk_free_gb.stdout | int >= 5
    fail_msg: >
      Host {{ inventory_hostname }} has only {{ disk_free_gb.stdout }}GB free on /.
      At least 5GB is required. Free up space before proceeding.
  tags: preflight
```

### 2. Create `playbooks/includes/preflight_k8s.yml`

```yaml
# playbooks/includes/preflight_k8s.yml
---
- name: Check that kubeconfig exists on control plane
  ansible.builtin.stat:
    path: /etc/kubernetes/admin.conf
  register: kubeconfig_stat
  delegate_to: "{{ k8s_control_plane_host }}"
  tags: preflight

- name: Assert cluster is initialized
  ansible.builtin.assert:
    that:
      - kubeconfig_stat.stat.exists
    fail_msg: >
      /etc/kubernetes/admin.conf not found on {{ k8s_control_plane_host }}.
      Run k8s.up.yml first to initialize the cluster.
  delegate_to: "{{ k8s_control_plane_host }}"
  tags: preflight

- name: Get cluster node status
  ansible.builtin.command: kubectl get nodes --no-headers
  register: node_status
  changed_when: false
  delegate_to: "{{ k8s_control_plane_host }}"
  tags: preflight

- name: Assert no nodes are in NotReady state
  ansible.builtin.assert:
    that:
      - "'NotReady' not in node_status.stdout"
    fail_msg: >
      One or more cluster nodes are in NotReady state:
      {{ node_status.stdout }}
      Resolve node issues before applying changes.
  delegate_to: "{{ k8s_control_plane_host }}"
  tags: preflight

- name: Assert required K8s variables are defined
  ansible.builtin.assert:
    that:
      - k8s_version is defined and k8s_version | length > 0
      - k8s_pod_cidr is defined
      - k8s_control_plane_host is defined
    fail_msg: "Required K8s variables are not defined. Check group_vars/k8s_control_plane.yml."
  tags: preflight
```

### 3. Add Pre-flight Play to Each Playbook

Add a dedicated pre-flight play at the **top** of each playbook, before the main play. Pattern:

```yaml
# k8s.cert-manager.yml (example)
---
- name: Pre-flight checks
  hosts: k8s_control_plane
  gather_facts: true
  tasks:
    - name: Common pre-flight checks
      ansible.builtin.import_tasks: includes/preflight_common.yml
    - name: K8s cluster pre-flight checks
      ansible.builtin.import_tasks: includes/preflight_k8s.yml

- name: Deploy cert-manager
  hosts: k8s_control_plane
  # ... rest of playbook
```

**Playbooks requiring only `preflight_common.yml`**:
- `prepare.up.yml`
- `user_management/user_management.up.yml`
- `security_hardening/security_hardening.up.yml`
- `system_config/system_config.up.yml`
- `apt_upgrade.yml`

**Playbooks requiring both `preflight_common.yml` and `preflight_k8s.yml`**:
- `kubernetes/k8s.metallb.yml`
- `kubernetes/k8s.cert-manager.yml`
- `kubernetes/k8s.storage.yml`
- `kubernetes/k8s.longhorn.yml`
- `kubernetes/k8s.logging.yml`
- `kubernetes/k8s.argocd.up.yml`
- `kubernetes/k8s.test.yml`

**Playbooks with specialized pre-flight (add inline asserts)**:
- `kubernetes/k8s.up.yml` — assert hosts unreachable via kubectl (cluster NOT yet initialized)
- `kubernetes/k8s.down.yml` — assert drain and node-delete are safe

### 4. Add Component-specific Variable Assertions

For each component playbook, add inline asserts for the variables it uses. Example for `k8s.logging.yml`:

```yaml
- name: Assert logging variables are defined
  ansible.builtin.assert:
    that:
      - logging_namespace is defined
      - logging_release_name is defined
      - logging_chart_version is defined
      - loki_storage_size is defined
      - grafana_nodeport is defined
    fail_msg: "Required logging variables are missing. Check group_vars/k8s_control_plane.yml."
  tags: preflight
```

### 5. Tag All Pre-flight Tasks

Every task in `preflight_common.yml` and `preflight_k8s.yml` must have `tags: preflight`. This enables:

```bash
# Run only pre-flight checks (no changes)
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.logging.yml --tags preflight

# Skip pre-flight (emergency use only — not recommended)
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.logging.yml --skip-tags preflight
```

---

## Verification

```bash
# Test: missing variable causes clear failure
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.logging.yml \
  -e "logging_namespace=" --tags preflight
# Expected: FAILED! => fail_msg describing the missing variable

# Test: pre-flight passes on healthy cluster
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.logging.yml \
  --tags preflight
# Expected: all assertions pass, playbook exits 0

# Test: pre-flight catches NotReady node
# (simulate by cordoning a node, then running)
kubectl cordon arthur
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.cert-manager.yml \
  --tags preflight
# Expected: FAILED! => fail_msg about NotReady node
kubectl uncordon arthur
```

---

## Subtasks

- [ ] Create `playbooks/includes/` directory
- [ ] Create `playbooks/includes/preflight_common.yml`
- [ ] Create `playbooks/includes/preflight_k8s.yml`
- [ ] Add pre-flight play to system/user/security playbooks (common only)
- [ ] Add pre-flight play to all K8s component playbooks (common + k8s)
- [ ] Add component-specific variable asserts to each K8s playbook
- [ ] Verify `--tags preflight` works across all updated playbooks
