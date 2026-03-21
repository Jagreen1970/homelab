# Task 06 — Post-Deployment Validation

**Status**: TODO
**Effort**: M (Medium)
**Phase**: 3 — Validation
**Dependencies**: Task 03 (preflight), Task 05 (idempotency)

---

## Goal

Standardize post-deployment health checks for every deployed component. Create a new `k8s.validate.yml` aggregator playbook that provides a single command to verify the entire cluster stack is healthy.

---

## Background

Currently `k8s.test.yml` provides some cluster health checks but it is primarily focused on node and pod status. Individual component playbooks (cert-manager, MetalLB, Longhorn, Loki/Grafana, ArgoCD) either have no post-deployment assertions or have inconsistent patterns. There is no way to verify the full stack without running each playbook individually.

The goal is to make validation a first-class concern: each component knows how to assert its own health, and a single `k8s.validate.yml` aggregates all component checks.

---

## Acceptance Criteria

- [ ] `playbooks/kubernetes/k8s.validate.yml` exists and runs all component health checks
- [ ] Each K8s component playbook ends with a `validate` tagged task block
- [ ] Validation includes Kubernetes API checks (`k8s_info` with `wait_condition`)
- [ ] Validation includes HTTP endpoint smoke tests via `ansible.builtin.uri`
- [ ] `k8s.validate.yml` exits 0 on a healthy cluster and non-0 on any failed component
- [ ] Running with `--tags validate` on any component playbook runs only its validation block

---

## Implementation Steps

### 1. Define Validation Standard Per Component

Each component gets a validation block tagged `validate` at the end of its playbook:

```yaml
# Validation block template (add to end of each component playbook)
- name: Validate {{ component }} deployment
  tags: validate
  block:
    - name: Wait for {{ component }} deployment to be Available
      kubernetes.core.k8s_info:
        kind: Deployment
        name: "{{ deployment_name }}"
        namespace: "{{ namespace }}"
        wait: true
        wait_timeout: 60
        wait_condition:
          type: Available
          status: "True"
      register: deploy_status
      failed_when: deploy_status.resources | length == 0

    - name: Smoke test {{ component }} HTTP endpoint
      ansible.builtin.uri:
        url: "{{ endpoint_url }}"
        validate_certs: false
        status_code: [200, 301, 302]
        timeout: 10
      delegate_to: localhost
      when: endpoint_url is defined
```

### 2. Component-Specific Validation Tasks

#### `k8s.cert-manager.yml` — append validation

```yaml
- name: Validate cert-manager stack
  hosts: k8s_control_plane
  gather_facts: false
  tags: validate
  tasks:
    - name: Wait for cert-manager deployment
      kubernetes.core.k8s_info:
        kind: Deployment
        name: cert-manager
        namespace: cert-manager
        wait: true
        wait_timeout: 60
        wait_condition:
          type: Available
          status: "True"
      register: cm_status
      failed_when: cm_status.resources | length == 0

    - name: Wait for cert-manager-webhook deployment
      kubernetes.core.k8s_info:
        kind: Deployment
        name: cert-manager-webhook
        namespace: cert-manager
        wait: true
        wait_timeout: 60
        wait_condition:
          type: Available
          status: "True"

    - name: List ClusterIssuers
      ansible.builtin.command: kubectl get clusterissuers
      register: issuers
      changed_when: false

    - name: Assert self-signed issuer exists
      ansible.builtin.assert:
        that:
          - "'selfsigned' in issuers.stdout"
        fail_msg: "selfsigned ClusterIssuer not found. Apply manifests/cert-manager/selfsigned-issuer.yaml"
```

#### `k8s.metallb.yml` — append validation

```yaml
- name: Validate MetalLB stack
  hosts: k8s_control_plane
  gather_facts: false
  tags: validate
  tasks:
    - name: Wait for MetalLB controller
      kubernetes.core.k8s_info:
        kind: Deployment
        name: controller
        namespace: metallb-system
        wait: true
        wait_timeout: 60
        wait_condition:
          type: Available
          status: "True"

    - name: Assert IPAddressPool exists
      ansible.builtin.command: kubectl get ipaddresspools -n metallb-system
      register: ippool
      changed_when: false
      failed_when: ippool.rc != 0

    - name: Assert L2Advertisement exists
      ansible.builtin.command: kubectl get l2advertisements -n metallb-system
      register: l2adv
      changed_when: false
      failed_when: l2adv.rc != 0
```

#### `k8s.longhorn.yml` — append validation

```yaml
- name: Validate Longhorn storage
  hosts: k8s_control_plane
  gather_facts: false
  tags: validate
  tasks:
    - name: Wait for Longhorn UI deployment
      kubernetes.core.k8s_info:
        kind: Deployment
        name: longhorn-ui
        namespace: longhorn-system
        wait: true
        wait_timeout: 120
        wait_condition:
          type: Available
          status: "True"

    - name: Assert Longhorn StorageClass exists
      ansible.builtin.command: kubectl get storageclass longhorn
      register: sc_check
      changed_when: false
      failed_when: sc_check.rc != 0

    - name: Smoke test Longhorn UI
      ansible.builtin.uri:
        url: "http://longhorn.{{ ansible_host }}"
        validate_certs: false
        status_code: [200, 301, 302]
        timeout: 10
      delegate_to: localhost
      failed_when: false  # UI may not be accessible from runner; non-blocking
```

#### `k8s.logging.yml` — append validation

```yaml
- name: Validate Loki/Grafana logging stack
  hosts: k8s_control_plane
  gather_facts: false
  tags: validate
  tasks:
    - name: Wait for Grafana deployment
      kubernetes.core.k8s_info:
        kind: Deployment
        name: "{{ logging_release_name }}-grafana"
        namespace: "{{ logging_namespace }}"
        wait: true
        wait_timeout: 120
        wait_condition:
          type: Available
          status: "True"

    - name: Smoke test Grafana NodePort
      ansible.builtin.uri:
        url: "http://{{ hostvars[k8s_control_plane_host]['ansible_host'] }}:{{ grafana_nodeport }}"
        status_code: [200, 302]
        timeout: 10
      delegate_to: localhost

    - name: Smoke test Loki readiness endpoint
      ansible.builtin.uri:
        url: "http://{{ hostvars[k8s_control_plane_host]['ansible_host'] }}:3100/ready"
        status_code: [200]
        timeout: 10
      delegate_to: localhost
      failed_when: false  # Loki may not expose NodePort directly
```

### 3. Create `playbooks/kubernetes/k8s.validate.yml`

```yaml
# playbooks/kubernetes/k8s.validate.yml
---
# Aggregated post-deployment validation for the full K8s stack.
# Runs all component health checks in sequence.
# Usage: ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.validate.yml

- name: Pre-flight — verify cluster is up
  hosts: k8s_control_plane
  gather_facts: true
  tasks:
    - name: Import K8s pre-flight checks
      ansible.builtin.import_tasks: includes/preflight_k8s.yml

- name: Validate MetalLB
  ansible.builtin.import_playbook: k8s.metallb.yml
  tags: [validate, metallb]

- name: Validate cert-manager
  ansible.builtin.import_playbook: k8s.cert-manager.yml
  tags: [validate, cert-manager]

- name: Validate Longhorn storage
  ansible.builtin.import_playbook: k8s.longhorn.yml
  tags: [validate, longhorn]

- name: Validate Logging stack
  ansible.builtin.import_playbook: k8s.logging.yml
  tags: [validate, logging]

- name: Validate ArgoCD
  ansible.builtin.import_playbook: k8s.argocd.up.yml
  tags: [validate, argocd]
```

> **Note**: When imported via `k8s.validate.yml`, component playbooks run with `--tags validate`, executing only their validation blocks. The `import_playbook` with `tags` passes the tag to all plays in the imported playbook.

### 4. Update `k8s.all.yml` to Run Validation

Add a final validation step to the master orchestration playbook:

```yaml
# At end of k8s.all.yml
- name: Post-deployment validation
  ansible.builtin.import_playbook: k8s.validate.yml
  tags: validate
```

---

## Verification

```bash
# Run full validation suite
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.validate.yml

# Run validation for a single component
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.cert-manager.yml --tags validate

# Validate only logging stack
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.validate.yml --tags logging
```

---

## Subtasks

- [ ] Audit `k8s.test.yml` for existing checks — migrate useful ones to component validate blocks
- [ ] Add `validate` block to `k8s.cert-manager.yml`
- [ ] Add `validate` block to `k8s.metallb.yml`
- [ ] Add `validate` block to `k8s.longhorn.yml`
- [ ] Add `validate` block to `k8s.logging.yml`
- [ ] Add `validate` block to `k8s.argocd.up.yml`
- [ ] Create `playbooks/kubernetes/k8s.validate.yml` aggregator
- [ ] Add uri smoke tests where appropriate (Grafana, ArgoCD, Longhorn UI)
- [ ] Update `k8s.all.yml` to import `k8s.validate.yml` at end
- [ ] Test: `ansible-playbook k8s.validate.yml` exits 0 on healthy cluster
