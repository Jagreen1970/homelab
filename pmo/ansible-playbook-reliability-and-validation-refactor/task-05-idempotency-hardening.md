# Task 05 — Idempotency Hardening

**Status**: TODO
**Effort**: M (Medium)
**Phase**: 2 — Hardening
**Dependencies**: Task 01 (linting), Task 04 (error handling)

---

## Goal

Ensure every playbook can be safely re-run on an already-configured system and report 0 changed tasks. Fix all `shell`/`command` tasks that lack proper `changed_when` conditions, and add `creates:` guards to prevent re-execution of one-time operations.

---

## Background

Idempotency is a core Ansible promise: running a playbook twice should produce the same end state, and the second run should report no changes on an already-configured system. Several tasks in this codebase violate this:

- `shell`/`command` tasks without `changed_when` always report "changed"
- Operations that check-then-create (e.g., Helm installs) may not detect an existing installation
- File-generation tasks re-create files on every run even if content is unchanged
- Service restart handlers fire on every run rather than only when config changes

This causes false positives in change tracking, makes diff-based auditing unreliable, and increases the risk of unintended side effects on repeated runs.

---

## Acceptance Criteria

- [ ] `ansible-lint --profile production` reports zero `no-changed-when` warnings
- [ ] Running any playbook twice in a row on an unchanged system reports 0 changed tasks
- [ ] All read-only `shell`/`command` tasks have `changed_when: false`
- [ ] All state-changing `command` tasks have explicit `changed_when` conditions
- [ ] File-generating tasks use checksums or `creates:` to avoid re-generation
- [ ] Handlers fire only when their notifying task actually changes state

---

## Audit: Common Idempotency Issues

Find all `shell`/`command` tasks lacking `changed_when`:

```bash
# Tasks that will report changed every run
grep -A5 -B1 "ansible.builtin.shell\|ansible.builtin.command" playbooks/kubernetes/k8s.up.yml | \
  grep -v "changed_when\|register\|when\|failed_when"
```

### Known Violations (to audit and fix)

**`k8s.up.yml`**:
- `sysctl -p` — always reports changed; add `changed_when: sysctl_result.rc == 0`
- `kubectl apply -f flannel.yaml` — already has `changed_when` but verify
- Token generation commands — genuinely change state but should use `changed_when: token_result.rc == 0`
- `kubeadm init` — correctly handled with `failed_when` + `changed_when: kubeadm_init.rc == 0`

**`k8s.cert-manager.yml`**:
- `kubectl apply -f cert-manager.yaml` — should use `changed_when` based on output containing "configured" or "created"
- `kubectl get clusterissuers` — read-only, needs `changed_when: false`

**`k8s.metallb.yml`**:
- `kubectl apply -f metallb.yaml` — add output-based `changed_when`
- `kubectl get pods -n metallb-system` — read-only, needs `changed_when: false`

**`k8s.longhorn.yml`**:
- `helm upgrade --install` — add `changed_when` based on helm output
- `kubectl exec` test commands — read-only, needs `changed_when: false`

---

## Implementation Steps

### 1. Fix Read-Only Commands

Any `command`/`shell` that only reads state must have `changed_when: false`:

```yaml
# BEFORE
- name: Get cluster nodes
  ansible.builtin.command: kubectl get nodes
  register: node_list

# AFTER
- name: Get cluster nodes
  ansible.builtin.command: kubectl get nodes
  register: node_list
  changed_when: false
```

### 2. Fix State-Changing Commands with Output Detection

For `kubectl apply`, detect actual changes from output:

```yaml
- name: Apply MetalLB manifest
  ansible.builtin.command: kubectl apply -f /tmp/metallb.yaml
  register: metallb_apply
  changed_when: >
    'configured' in metallb_apply.stdout or
    'created' in metallb_apply.stdout
```

For Helm:

```yaml
- name: Install Longhorn via Helm
  ansible.builtin.command: >
    helm upgrade --install longhorn longhorn/longhorn
    --namespace longhorn-system
    --version {{ longhorn_version }}
  register: helm_longhorn
  changed_when: >
    'has been upgraded' in helm_longhorn.stdout or
    'has been installed' in helm_longhorn.stdout
```

### 3. Add `creates:` to One-Time File Generation

If a command generates a file that shouldn't be regenerated:

```yaml
# Generate kubeconfig for admin user
- name: Copy kubeconfig for admin user
  ansible.builtin.command: >
    cp /etc/kubernetes/admin.conf /home/{{ k8s_admin_user }}/.kube/config
  args:
    creates: /home/{{ k8s_admin_user }}/.kube/config
```

### 4. Audit Service Handlers

Handlers should only fire when their notifying task is changed. Check all handlers in security, system_config, and user_management playbooks:

```yaml
# CORRECT pattern — handler only fires when task reports changed
- name: Configure SSH
  ansible.builtin.template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    mode: "0600"
  notify: Restart SSH
```

If a handler fires on every run even with no changes, investigate whether the notifying task has correct idempotency.

### 5. Use `ansible.builtin.copy` with Content-Based Detection

For inline config writes, prefer `ansible.builtin.copy` with `content:` over shell heredocs. The `copy` module automatically detects if content changed:

```yaml
# PREFER this (idempotent)
- name: Write containerd config
  ansible.builtin.copy:
    content: |
      version = 2
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type = "io.containerd.runc.v2"
    dest: /etc/containerd/config.toml
    mode: "0644"
  notify: Restart containerd

# AVOID this (always changed)
- name: Write containerd config
  ansible.builtin.shell: |
    cat > /etc/containerd/config.toml << 'EOF'
    ...
    EOF
```

### 6. Verify Helm Idempotency

Helm `upgrade --install` is idempotent by design when:
- `--install` flag is present (install if not exists, upgrade if exists)
- `--version` is pinned (not `latest`)
- Values haven't changed

Verify all Helm tasks use `upgrade --install` (not bare `install`) and have pinned versions.

---

## Verification

```bash
# First run — expected changes
ansible-playbook -i inventory.yml playbooks/security_hardening/security_hardening.up.yml

# Second run — expected: 0 changed
ansible-playbook -i inventory.yml playbooks/security_hardening/security_hardening.up.yml
# Verify output: "changed=0" for all hosts

# Repeat for each playbook domain
ansible-playbook -i inventory.yml playbooks/system_config/system_config.up.yml
# Second run: "changed=0"

ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.cert-manager.yml
# Second run: "changed=0"
```

---

## Subtasks

- [ ] Audit all `shell`/`command` tasks in `playbooks/kubernetes/k8s.up.yml` for `changed_when`
- [ ] Audit all `shell`/`command` tasks in `k8s.cert-manager.yml`, `k8s.metallb.yml`
- [ ] Audit all `shell`/`command` tasks in `k8s.longhorn.yml`, `k8s.logging.yml`
- [ ] Add `changed_when: false` to all read-only commands
- [ ] Add output-based `changed_when` to all `kubectl apply` commands
- [ ] Add output-based `changed_when` to all `helm upgrade` commands
- [ ] Replace shell heredoc config writes with `ansible.builtin.copy content:` where applicable
- [ ] Add `creates:` to one-time file generation commands
- [ ] Audit handlers in security, system_config, user_management playbooks
- [ ] Run each playbook twice and verify second run shows 0 changed
