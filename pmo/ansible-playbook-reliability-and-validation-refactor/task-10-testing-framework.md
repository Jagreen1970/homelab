# Task 10 — Testing Framework

**Status**: TODO
**Effort**: L (Large)
**Phase**: 4 — Refactor
**Dependencies**: Task 08 (role refactoring)

---

## Goal

Introduce automated testing at two levels:
1. **Unit tests** via Molecule for each Ansible role (fast, Docker-based, no real K8s needed)
2. **Integration tests** via dedicated playbooks that deploy test workloads and assert outcomes against the real cluster

---

## Background

Currently there is no automated testing. The only validation is `k8s.test.yml`, which is a manual cluster inspection playbook, not a proper test suite. Without automated tests:

- Changes to roles or playbooks can't be validated before being applied to the cluster
- There is no safety net for the role refactoring done in Task 08
- Regression testing requires full cluster re-deployment

Molecule provides a framework for testing Ansible roles in isolation using Docker containers. Integration test playbooks exercise real cluster functionality (create a PVC, assert it's Bound, then clean up).

---

## Acceptance Criteria

- [ ] Molecule is configured for all three roles (`common`, `k8s_node`, `k8s_addons`)
- [ ] `molecule test` passes for `roles/common/` (kernel module, sysctl, package assertions)
- [ ] Integration test playbooks exist for: MetalLB, cert-manager, Longhorn
- [ ] `make test-unit` runs all Molecule tests
- [ ] `make test-integration` runs all integration test playbooks
- [ ] Testing setup is documented in `CLAUDE.md`

---

## Implementation Steps

### 1. Install Molecule and Dependencies

```bash
pip install molecule molecule-plugins[docker] ansible-lint
# Or add to requirements.txt:
# molecule>=24.0
# molecule-plugins[docker]>=23.0
```

Create `requirements.txt` at repo root (if not exists):

```
ansible>=2.14
ansible-lint>=24.0
molecule>=24.0
molecule-plugins[docker]>=23.0
yamllint>=1.35
```

### 2. Initialize Molecule for Each Role

```bash
cd roles/common && molecule init scenario --driver-name docker
cd roles/k8s_node && molecule init scenario --driver-name docker
cd roles/k8s_addons && molecule init scenario --driver-name docker
```

This creates `molecule/default/` in each role directory.

### 3. Configure `roles/common/molecule/default/`

**`molecule.yml`**:
```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: ubuntu:22.04
    pre_build_image: true
    privileged: true  # needed for sysctl and kernel module tests
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    command: /sbin/init
provisioner:
  name: ansible
verifier:
  name: ansible
```

**`converge.yml`**:
```yaml
---
- name: Converge
  hosts: all
  roles:
    - role: common
```

**`verify.yml`** (assertions):
```yaml
---
- name: Verify common role
  hosts: all
  gather_facts: true
  tasks:
    - name: Assert required packages are installed
      ansible.builtin.package_facts:
        manager: auto

    - name: Assert curl is installed
      ansible.builtin.assert:
        that:
          - "'curl' in ansible_facts.packages"
        fail_msg: "curl package is not installed"

    - name: Assert ip_forward is enabled
      ansible.builtin.command: sysctl net.ipv4.ip_forward
      register: ip_forward
      changed_when: false

    - name: Assert ip_forward value
      ansible.builtin.assert:
        that:
          - "'= 1' in ip_forward.stdout"
        fail_msg: "net.ipv4.ip_forward is not enabled"

    - name: Assert swap is disabled
      ansible.builtin.command: swapon --summary
      register: swap_status
      changed_when: false

    - name: Assert no active swap
      ansible.builtin.assert:
        that:
          - swap_status.stdout | length == 0
        fail_msg: "Swap is still active: {{ swap_status.stdout }}"
```

### 4. Configure `roles/k8s_node/molecule/default/`

**`verify.yml`**:
```yaml
---
- name: Verify k8s_node role
  hosts: all
  gather_facts: true
  tasks:
    - name: Assert containerd is installed
      ansible.builtin.package_facts:

    - name: Assert containerd package present
      ansible.builtin.assert:
        that:
          - "'containerd.io' in ansible_facts.packages or 'containerd' in ansible_facts.packages"

    - name: Assert containerd service is running
      ansible.builtin.service_facts:

    - name: Assert containerd is active
      ansible.builtin.assert:
        that:
          - "'containerd' in ansible_facts.services"
          - "ansible_facts.services['containerd'].state == 'running'"

    - name: Assert kubeadm is installed and in PATH
      ansible.builtin.command: kubeadm version
      register: kubeadm_version
      changed_when: false
      failed_when: kubeadm_version.rc != 0

    - name: Assert kubectl is installed and in PATH
      ansible.builtin.command: kubectl version --client
      register: kubectl_version
      changed_when: false
      failed_when: kubectl_version.rc != 0
```

### 5. Integration Test Playbooks

Create `playbooks/tests/integration/` directory.

#### `test_metallb.yml`

```yaml
# playbooks/tests/integration/test_metallb.yml
---
- name: Integration test — MetalLB LoadBalancer assignment
  hosts: k8s_control_plane
  gather_facts: false
  vars:
    test_namespace: metallb-test
    test_service_name: metallb-test-svc
  tasks:
    - name: Create test namespace
      kubernetes.core.k8s:
        kind: Namespace
        name: "{{ test_namespace }}"
        state: present

    - name: Deploy test nginx
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: nginx-test
            namespace: "{{ test_namespace }}"
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: nginx-test
            template:
              metadata:
                labels:
                  app: nginx-test
              spec:
                containers:
                  - name: nginx
                    image: nginx:alpine

    - name: Create LoadBalancer service
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: "{{ test_service_name }}"
            namespace: "{{ test_namespace }}"
          spec:
            type: LoadBalancer
            selector:
              app: nginx-test
            ports:
              - port: 80

    - name: Wait for external IP assignment (up to 60s)
      kubernetes.core.k8s_info:
        kind: Service
        name: "{{ test_service_name }}"
        namespace: "{{ test_namespace }}"
      register: svc_info
      until: >
        svc_info.resources | length > 0 and
        svc_info.resources[0].status.loadBalancer.ingress | default([]) | length > 0
      retries: 12
      delay: 5

    - name: Assert external IP was assigned
      ansible.builtin.assert:
        that:
          - svc_info.resources[0].status.loadBalancer.ingress | length > 0
        fail_msg: "MetalLB did not assign an external IP to the test LoadBalancer service"

    - name: Show assigned IP
      ansible.builtin.debug:
        msg: "LoadBalancer IP: {{ svc_info.resources[0].status.loadBalancer.ingress[0].ip }}"

  always:
    - name: Cleanup test namespace
      kubernetes.core.k8s:
        kind: Namespace
        name: "{{ test_namespace }}"
        state: absent
```

#### `test_cert_manager.yml`

```yaml
# playbooks/tests/integration/test_cert_manager.yml
---
- name: Integration test — cert-manager Certificate issuance
  hosts: k8s_control_plane
  gather_facts: false
  vars:
    test_namespace: cert-test
  tasks:
    - name: Create test namespace
      kubernetes.core.k8s:
        kind: Namespace
        name: "{{ test_namespace }}"
        state: present

    - name: Create test Certificate
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: cert-manager.io/v1
          kind: Certificate
          metadata:
            name: test-certificate
            namespace: "{{ test_namespace }}"
          spec:
            secretName: test-tls
            issuerRef:
              name: selfsigned
              kind: ClusterIssuer
            commonName: test.homelab.local
            dnsNames:
              - test.homelab.local

    - name: Wait for Certificate to be Ready (up to 60s)
      kubernetes.core.k8s_info:
        api_version: cert-manager.io/v1
        kind: Certificate
        name: test-certificate
        namespace: "{{ test_namespace }}"
        wait: true
        wait_timeout: 60
        wait_condition:
          type: Ready
          status: "True"
      register: cert_status

    - name: Assert Certificate is Ready
      ansible.builtin.assert:
        that:
          - cert_status.resources | length > 0
        fail_msg: "test-certificate did not reach Ready state within 60s"

  always:
    - name: Cleanup test namespace
      kubernetes.core.k8s:
        kind: Namespace
        name: "{{ test_namespace }}"
        state: absent
```

#### `test_longhorn.yml`

```yaml
# playbooks/tests/integration/test_longhorn.yml
---
- name: Integration test — Longhorn PVC provisioning
  hosts: k8s_control_plane
  gather_facts: false
  vars:
    test_namespace: longhorn-test
  tasks:
    - name: Create test namespace
      kubernetes.core.k8s:
        kind: Namespace
        name: "{{ test_namespace }}"
        state: present

    - name: Create PVC using Longhorn storage class
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: PersistentVolumeClaim
          metadata:
            name: test-pvc
            namespace: "{{ test_namespace }}"
          spec:
            accessModes:
              - ReadWriteOnce
            storageClassName: longhorn
            resources:
              requests:
                storage: 1Gi

    - name: Wait for PVC to be Bound (up to 120s)
      kubernetes.core.k8s_info:
        kind: PersistentVolumeClaim
        name: test-pvc
        namespace: "{{ test_namespace }}"
      register: pvc_status
      until: >
        pvc_status.resources | length > 0 and
        pvc_status.resources[0].status.phase == 'Bound'
      retries: 24
      delay: 5

    - name: Assert PVC is Bound
      ansible.builtin.assert:
        that:
          - pvc_status.resources[0].status.phase == 'Bound'
        fail_msg: "Longhorn PVC did not reach Bound state — check Longhorn volumes in the UI"

  always:
    - name: Cleanup test namespace
      kubernetes.core.k8s:
        kind: Namespace
        name: "{{ test_namespace }}"
        state: absent
```

### 6. Add `make` Targets

Update `Makefile`:

```makefile
test-unit: ## Run Molecule unit tests for all roles
	cd roles/common && molecule test
	cd roles/k8s_node && molecule test
	cd roles/k8s_addons && molecule test

test-integration: ## Run integration tests against the real cluster
	ansible-playbook -i $(INVENTORY) playbooks/tests/integration/test_metallb.yml
	ansible-playbook -i $(INVENTORY) playbooks/tests/integration/test_cert_manager.yml
	ansible-playbook -i $(INVENTORY) playbooks/tests/integration/test_longhorn.yml

test: test-unit test-integration ## Run all tests
```

### 7. Document in `CLAUDE.md`

Add a `## Testing` section:

```markdown
## Testing

### Unit Tests (Molecule — no cluster required)
```bash
make test-unit
# or per-role:
cd roles/common && molecule test
```

### Integration Tests (requires running cluster)
```bash
make test-integration
```

Integration tests create temporary namespaces, assert outcomes, then clean up. They are safe to run against a production cluster.
```

---

## Verification

```bash
# Unit tests pass
make test-unit
# Expected: molecule test exits 0 for all roles

# Integration tests pass
make test-integration
# Expected: each test playbook exits 0 with assertions passing
```

---

## Subtasks

- [ ] Create `requirements.txt` with Molecule dependencies
- [ ] Initialize Molecule for `roles/common/`
- [ ] Write `roles/common/molecule/default/verify.yml`
- [ ] Initialize Molecule for `roles/k8s_node/`
- [ ] Write `roles/k8s_node/molecule/default/verify.yml`
- [ ] Initialize Molecule for `roles/k8s_addons/`
- [ ] Write `roles/k8s_addons/molecule/default/verify.yml`
- [ ] Create `playbooks/tests/integration/test_metallb.yml`
- [ ] Create `playbooks/tests/integration/test_cert_manager.yml`
- [ ] Create `playbooks/tests/integration/test_longhorn.yml`
- [ ] Add `make test-unit`, `make test-integration`, `make test` to `Makefile`
- [ ] Update `CLAUDE.md` with testing documentation
- [ ] Run `make test-unit` — all pass
- [ ] Run `make test-integration` — all pass
