# Task 04 — Error Handling with Block/Rescue

**Status**: TODO
**Effort**: L (Large)
**Phase**: 2 — Hardening
**Dependencies**: Task 01 (linting)

---

## Goal

Replace broad `failed_when: false` and `ignore_errors: true` usage with targeted `block/rescue/always` patterns so that failures produce clear diagnostic output, trigger cleanup/rollback where appropriate, and never silently corrupt state.

---

## Background

The codebase currently suppresses many errors broadly:
- `ignore_errors: true` on critical operations (node join, helm deploys) means a failing step doesn't stop the playbook
- `failed_when: false` on some tasks hides real errors entirely
- When something fails mid-deployment, there is no rollback — the system is left in a partial state with no guidance

The Ansible `block/rescue/always` construct enables structured error handling:
- `block`: the main task(s)
- `rescue`: runs only when the block fails — log the error, attempt cleanup, then re-raise
- `always`: runs regardless — cleanup resources that must always be released

---

## Acceptance Criteria

- [ ] All occurrences of `ignore_errors: true` on non-trivial operations are replaced
- [ ] All occurrences of `failed_when: false` are either justified (read-only optional checks) or replaced with `block/rescue`
- [ ] Critical operations (kubeadm init, node join, Helm deploy) have rescue blocks with diagnostic output
- [ ] Rescue blocks for destructive operations include rollback/cleanup tasks
- [ ] `ansible.builtin.fail` with a clear `msg` re-raises the error after rescue cleanup
- [ ] A comment documents the intent of any remaining `failed_when: false` usage

---

## Audit: Current Problematic Patterns

Run to find all instances:

```bash
grep -rn "ignore_errors\|failed_when: false" playbooks/
```

### `playbooks/kubernetes/k8s.up.yml`

| Location | Pattern | Classification |
|----------|---------|----------------|
| Worker node join | `ignore_errors: true` | (b) should fail with recovery — node may already be joined |
| Flannel apply | `ignore_errors: true` | (b) should fail with recovery |
| Dashboard apply | `ignore_errors: true` | (a) intentionally optional |
| kubeadm reset | `failed_when: false` | (a) cleanup — OK |

### `playbooks/kubernetes/k8s.metallb.yml`

| Location | Pattern | Classification |
|----------|---------|----------------|
| Check LoadBalancer IP | `ignore_errors: true` | (a) validation — replace with `failed_when` condition |

### `playbooks/kubernetes/k8s.longhorn.yml`

| Location | Pattern | Classification |
|----------|---------|----------------|
| Test pod exec | `failed_when: false` | (a) intentionally optional test — add comment |
| Longhorn Helm install | `failed_when: false` | (b) should fail with recovery |

### `playbooks/kubernetes/k8s.logging.yml`

| Location | Pattern | Classification |
|----------|---------|----------------|
| Helm upgrade/install | multiple | (b) should fail with recovery |

---

## Implementation Steps

### 1. Classify All Instances

For each occurrence found by grep, assign category:
- **(a) Intentionally optional**: Keep `failed_when: false` but add an explanatory comment + `debug` on failure
- **(b) Should fail with recovery**: Wrap in `block/rescue`
- **(c) Should always fail**: Remove suppression entirely

### 2. Template: Block/Rescue for Helm Deployments

Apply to `k8s.longhorn.yml`, `k8s.logging.yml`, `k8s.argocd.up.yml`:

```yaml
- name: Deploy {{ component_name }} via Helm
  block:
    - name: Install or upgrade {{ component_name }} Helm chart
      ansible.builtin.command: >
        helm upgrade --install {{ release_name }} {{ chart_name }}
        --namespace {{ namespace }}
        --create-namespace
        --version {{ chart_version }}
        --values {{ values_file }}
        --wait --timeout 300s
      register: helm_deploy_result
      changed_when: "'has been upgraded' in helm_deploy_result.stdout or
                     'has been installed' in helm_deploy_result.stdout"

  rescue:
    - name: Show Helm deploy failure details
      ansible.builtin.debug:
        msg: |
          Helm deployment failed for {{ component_name }}:
          stdout: {{ helm_deploy_result.stdout | default('(no output)') }}
          stderr: {{ helm_deploy_result.stderr | default('(no output)') }}

    - name: Get pod status in namespace (diagnostic)
      ansible.builtin.command: kubectl get pods -n {{ namespace }} --no-headers
      register: pod_diag
      changed_when: false
      failed_when: false

    - name: Show pod status
      ansible.builtin.debug:
        msg: "{{ pod_diag.stdout_lines | default([]) }}"

    - name: Fail with actionable message
      ansible.builtin.fail:
        msg: >
          {{ component_name }} Helm deployment failed.
          Check pod logs above. To retry: ansible-playbook -i inventory.yml
          playbooks/kubernetes/{{ playbook_name }} --tags install
```

### 3. Template: Block/Rescue for kubeadm init (`k8s.up.yml`)

```yaml
- name: Initialize Kubernetes control plane
  block:
    - name: Run kubeadm init
      ansible.builtin.command: >
        kubeadm init
        --pod-network-cidr={{ k8s_pod_cidr }}
        --kubernetes-version={{ k8s_version }}
      register: kubeadm_init
      failed_when: >
        kubeadm_init.rc != 0 and
        "already exists" not in kubeadm_init.stderr
      changed_when: kubeadm_init.rc == 0

  rescue:
    - name: Show kubeadm init error
      ansible.builtin.debug:
        msg: "kubeadm init failed: {{ kubeadm_init.stderr }}"

    - name: Reset kubeadm state (cleanup)
      ansible.builtin.command: kubeadm reset --force
      failed_when: false
      changed_when: true

    - name: Fail with recovery guidance
      ansible.builtin.fail:
        msg: >
          Cluster initialization failed. State has been reset.
          Check the error above and re-run k8s.up.yml.
```

### 4. Template: Block/Rescue for Worker Node Join (`k8s.up.yml`)

```yaml
- name: Join worker nodes to cluster
  block:
    - name: Join {{ inventory_hostname }} to cluster
      ansible.builtin.command: "{{ hostvars[k8s_control_plane_host]['join_command'].stdout }}"
      register: join_result
      failed_when: >
        join_result.rc != 0 and
        "already a member" not in join_result.stderr and
        "already exists" not in join_result.stderr
      changed_when: join_result.rc == 0

  rescue:
    - name: Show join error
      ansible.builtin.debug:
        msg: "Node join failed on {{ inventory_hostname }}: {{ join_result.stderr }}"

    - name: Reset node state
      ansible.builtin.command: kubeadm reset --force
      failed_when: false
      changed_when: true

    - name: Fail
      ansible.builtin.fail:
        msg: >
          Worker node {{ inventory_hostname }} failed to join cluster.
          Node state has been reset. Check network connectivity and token validity.
```

### 5. Document Remaining `failed_when: false` Usage

For any `failed_when: false` kept for category (a), add a comment:

```yaml
- name: Retrieve test pod content (optional — pod may not be running)
  kubernetes.core.k8s_exec:
    namespace: default
    pod: longhorn-storage-test
    command: cat /data/longhorn-test.txt
  register: test_pod_result
  failed_when: false  # intentional: test pod is optional; failure is logged below

- name: Log test pod result
  ansible.builtin.debug:
    msg: >
      {% if test_pod_result.rc | default(1) == 0 %}
      Test pod content: {{ test_pod_result.stdout }}
      {% else %}
      Test pod exec skipped or failed (non-blocking).
      {% endif %}
```

---

## Verification

```bash
# Test rescue fires on intentional failure
# Temporarily corrupt a chart version in k8s_vars.yml, then run:
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.logging.yml --tags install
# Expected: rescue block fires, shows diagnostic output, fails with actionable message

# Verify no unguarded ignore_errors remain in critical paths
grep -rn "ignore_errors: true" playbooks/kubernetes/k8s.up.yml
# Expected: 0 results (or only the dashboard deploy, which is intentionally optional)
```

---

## Subtasks

- [ ] Audit all playbooks: inventory every `failed_when: false` and `ignore_errors`
- [ ] Classify each occurrence as (a), (b), or (c)
- [ ] Implement `block/rescue` for kubeadm init in `k8s.up.yml`
- [ ] Implement `block/rescue` for worker node join in `k8s.up.yml`
- [ ] Implement `block/rescue` for Helm deploy in `k8s.longhorn.yml`
- [ ] Implement `block/rescue` for Helm deploy in `k8s.logging.yml`
- [ ] Implement `block/rescue` for Helm deploy in `k8s.argocd.up.yml`
- [ ] Add comments to all remaining `failed_when: false` category (a) occurrences
- [ ] Remove all category (c) error suppression
- [ ] Verify lint passes after changes
