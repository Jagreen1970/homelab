# Task 09 — Ansible Deprecations

**Status**: TODO
**Effort**: M (Medium)
**Phase**: 2 — Hardening
**Dependencies**: Task 01 (linting)

> **Note**: K8s and Helm component version updates are out of scope for this plan. They belong as a follow-on in `pmo/k8s-reliability-improvements/` after task-01 (K8s upgrade) completes. This task addresses only Ansible language-level deprecations.

---

## Goal

Audit all 30 playbooks for deprecated Ansible patterns and replace them with current idioms. Ensure the codebase is compatible with Ansible 2.14+ and produces zero deprecation warnings.

---

## Background

Ansible evolves quickly and deprecates patterns each minor release. Running playbooks with deprecated syntax produces warnings that clutter output and eventually become errors. The codebase was likely written across several Ansible versions, accumulating debt:

- `with_items:` (deprecated since 2.5 in favor of `loop:`)
- `include:` (deprecated since 2.8 in favor of `import_tasks:`/`include_tasks:`)
- `warn: false` in `shell`/`command` (removed in 2.14)
- Short module names like `copy:`, `apt:`, `template:` (all FQCNs required since 2.9 for lint; community best practice)
- Bare variable references in `when:` without `| bool` or `is defined`

---

## Acceptance Criteria

- [ ] `ansible-lint --profile production` reports zero `deprecated-*` tagged warnings
- [ ] `ansible-playbook --syntax-check` on all playbooks emits no deprecation messages
- [ ] Zero `with_items:`, `with_dict:`, `with_fileglob:`, `with_first_found:` in codebase
- [ ] Zero bare `include:` module usage (replaced with `import_tasks:` or `include_tasks:`)
- [ ] Zero `warn: false` in `shell`/`command` tasks
- [ ] All module names are fully qualified (FQCN)
- [ ] All boolean `when:` conditions use explicit `| bool` or `is defined` filters

---

## Deprecated Pattern Reference

| Deprecated | Replacement | Since |
|-----------|-------------|-------|
| `with_items:` | `loop:` | Ansible 2.5 |
| `with_dict:` | `loop: "{{ dict \| dict2items }}"` | Ansible 2.5 |
| `with_fileglob:` | `loop: "{{ lookup('fileglob', '...') }}"` | Ansible 2.5 |
| `with_first_found:` | `loop:` with `first_found` lookup | Ansible 2.8 |
| `include:` (static) | `ansible.builtin.import_tasks:` | Ansible 2.8 |
| `include:` (dynamic) | `ansible.builtin.include_tasks:` | Ansible 2.8 |
| `warn: false` in shell/command | Remove the key entirely | Ansible 2.14 |
| Short module names (`copy:`, `apt:`) | Fully qualified (`ansible.builtin.copy:`) | Best practice 2.9+ |
| Bare `when: my_var` for boolean | `when: my_var \| bool` | 2.8+ |
| `bare variables` in conditionals | Explicit Jinja2 expressions | 2.12+ |
| `_raw_params` complex args | `argv:` list | 2.11+ |

---

## Implementation Steps

### 1. Baseline Scan

Run the full audit to see current state:

```bash
# Deprecation warnings from lint
ansible-lint --profile production --tags deprecations playbooks/ 2>&1 | grep -E "deprecated|warn"

# Syntax check all playbooks for warnings
for pb in playbooks/*.yml playbooks/kubernetes/*.yml; do
  echo "=== $pb ===" && ansible-playbook -i inventory.yml "$pb" --syntax-check 2>&1 | grep -i "deprecat\|warn"
done

# Count each pattern
echo "with_items:"; grep -rn "with_items:" playbooks/ | wc -l
echo "with_dict:"; grep -rn "with_dict:" playbooks/ | wc -l
echo "bare include:"; grep -rn "^\s*include:" playbooks/ | wc -l
echo "warn: false"; grep -rn "warn: false" playbooks/ | wc -l
```

### 2. Replace `with_items:` with `loop:`

**Pattern**:
```yaml
# BEFORE
- name: Install packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  with_items:
    - curl
    - git
    - htop

# AFTER
- name: Install packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  loop:
    - curl
    - git
    - htop
```

For multi-item objects:
```yaml
# BEFORE
- name: Configure UFW rules
  community.general.ufw:
    rule: allow
    port: "{{ item.port }}"
    proto: "{{ item.proto }}"
  with_items: "{{ ufw_allowed_ports }}"

# AFTER
- name: Configure UFW rules
  community.general.ufw:
    rule: allow
    port: "{{ item.port }}"
    proto: "{{ item.proto }}"
  loop: "{{ ufw_allowed_ports }}"
```

### 3. Replace `with_dict:` with `loop:` + `dict2items`

```yaml
# BEFORE
- name: Set sysctl values
  ansible.posix.sysctl:
    name: "{{ item.key }}"
    value: "{{ item.value }}"
  with_dict: "{{ sysctl_settings }}"

# AFTER
- name: Set sysctl values
  ansible.posix.sysctl:
    name: "{{ item.key }}"
    value: "{{ item.value }}"
  loop: "{{ sysctl_settings | dict2items }}"
```

### 4. Replace Bare `include:` with `import_tasks:` or `include_tasks:`

**Rule for choosing**:
- `import_tasks:` (static): file is known at parse time, no dynamic variables in path → use for pre-flight, validation includes
- `include_tasks:` (dynamic): path contains variables, or you need `when:` at the include level

```yaml
# BEFORE
- include: tasks/setup_containerd.yml

# AFTER (static — path is literal)
- ansible.builtin.import_tasks: tasks/setup_containerd.yml

# AFTER (dynamic — path uses variable)
- ansible.builtin.include_tasks: "tasks/{{ runtime }}_setup.yml"
```

### 5. Remove `warn: false`

The `warn` parameter in `shell`/`command` tasks was deprecated in Ansible 2.11 and removed in 2.14. Simply delete it:

```yaml
# BEFORE
- name: Run kubeadm init
  ansible.builtin.shell: kubeadm init ...
  args:
    warn: false

# AFTER
- name: Run kubeadm init
  ansible.builtin.shell: kubeadm init ...
```

### 6. Qualify All Remaining Short Module Names

Find remaining unqualified module usage:

```bash
# Find tasks using short names (pattern: "^    - name:" followed by "  copy:", "  apt:", etc.)
grep -rn "^\s\+copy:\|^\s\+template:\|^\s\+service:\|^\s\+apt:\|^\s\+file:\|^\s\+stat:\|^\s\+debug:\|^\s\+shell:\|^\s\+command:\|^\s\+set_fact:" playbooks/
```

Replace each with FQCN:

| Short | Qualified |
|-------|-----------|
| `copy:` | `ansible.builtin.copy:` |
| `template:` | `ansible.builtin.template:` |
| `service:` | `ansible.builtin.service:` |
| `apt:` | `ansible.builtin.apt:` |
| `file:` | `ansible.builtin.file:` |
| `stat:` | `ansible.builtin.stat:` |
| `debug:` | `ansible.builtin.debug:` |
| `shell:` | `ansible.builtin.shell:` |
| `command:` | `ansible.builtin.command:` |
| `set_fact:` | `ansible.builtin.set_fact:` |
| `lineinfile:` | `ansible.builtin.lineinfile:` |
| `ping:` | `ansible.builtin.ping:` |
| `fail:` | `ansible.builtin.fail:` |
| `assert:` | `ansible.builtin.assert:` |
| `sysctl:` | `ansible.posix.sysctl:` |
| `ufw:` | `community.general.ufw:` |
| `sudoers:` | `community.general.sudoers:` |

### 7. Fix Bare Boolean `when:` Conditions

```yaml
# BEFORE (bare variable — deprecated in strict mode)
- name: Install Fail2ban
  ansible.builtin.apt:
    name: fail2ban
  when: fail2ban_enabled

# AFTER (explicit boolean cast)
- name: Install Fail2ban
  ansible.builtin.apt:
    name: fail2ban
  when: fail2ban_enabled | bool
```

### 8. Final Verification Pass

```bash
# Zero deprecation warnings
ansible-lint --profile production playbooks/

# Zero syntax warnings
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml --syntax-check 2>&1 | grep -ic "deprecat"
# Expected: 0
```

---

## Verification

```bash
# No deprecated patterns remain
grep -rn "with_items:\|with_dict:\|with_fileglob:\|with_first_found:" playbooks/
# Expected: no matches

grep -rn "^\s*include:" playbooks/
# Expected: no matches (all replaced with import_tasks/include_tasks)

grep -rn "warn: false" playbooks/
# Expected: no matches

# Lint clean
ansible-lint --profile production playbooks/ 2>&1 | grep -c "deprecated"
# Expected: 0
```

---

## Subtasks

- [ ] Run baseline scan — count all deprecated patterns
- [ ] Replace all `with_items:` with `loop:` across all playbooks
- [ ] Replace all `with_dict:` with `loop: + dict2items`
- [ ] Replace all bare `include:` with `import_tasks:` or `include_tasks:`
- [ ] Remove all `warn: false` from `shell`/`command` tasks
- [ ] Qualify all remaining short module names (grep-and-replace)
- [ ] Fix bare boolean `when:` conditions with `| bool`
- [ ] Run final lint scan — zero deprecation warnings
- [ ] Run syntax-check on all playbooks — zero warnings
