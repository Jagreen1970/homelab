# Task 01 — Standards & Linting Infrastructure

**Status**: TODO
**Effort**: S (Small)
**Phase**: 1 — Foundation
**Dependencies**: None

---

## Goal

Introduce automated linting and syntax enforcement so playbook quality is checked before every run. Provide a `Makefile` as a single entry point for all common operations.

---

## Background

Currently there is no `.ansible-lint` config, no `.yamllint.yml`, and no Makefile. The CLAUDE.md documents `ansible-lint` and `yamllint` as available commands but they run with default settings, which are noisy and inconsistent. Without pinned rules, violations accumulate silently and developers run playbooks without any quality gate.

---

## Acceptance Criteria

- [ ] `.ansible-lint` exists at repo root with `profile: production` and project-specific skip rules documented
- [ ] `.yamllint.yml` exists at repo root with 2-space indent, 120-char line length, enforced truthy values
- [ ] `Makefile` exists at repo root with targets: `lint`, `syntax-check`, `check`, `ping`, `help`
- [ ] `.pre-commit-config.yaml` exists with ansible-lint and yamllint hooks
- [ ] `make lint` exits 0 (all existing violations fixed)
- [ ] `make syntax-check` exits 0
- [ ] CLAUDE.md `## Commands` section updated to reference `make` targets

---

## Implementation Steps

### 1. Create `.ansible-lint`

```yaml
# .ansible-lint
---
profile: production

# Paths to exclude from linting
exclude_paths:
  - .git/
  - .ansible/
  - molecule/

# Rules to skip with justification
skip_list:
  - yaml[line-length]  # managed by yamllint separately
  - no-free-form       # kubeadm commands use free-form legitimately

# Rules to warn (not fail) on
warn_list:
  - experimental

# Offline mode — don't check for role updates
offline: true
```

### 2. Create `.yamllint.yml`

```yaml
# .yamllint.yml
---
extends: default

rules:
  line-length:
    max: 120
    level: warning
  indentation:
    spaces: 2
    indent-sequences: true
  truthy:
    allowed-values: ["true", "false", "yes", "no"]
    check-keys: false
  comments:
    min-spaces-from-content: 1
  braces:
    max-spaces-inside: 1
  brackets:
    max-spaces-inside: 1
```

### 3. Create `Makefile`

```makefile
# Makefile
INVENTORY ?= inventory.yml
PLAYBOOK ?= playbooks/kubernetes/k8s.all.yml

.PHONY: help lint syntax-check check ping

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Run ansible-lint and yamllint on all playbooks
	ansible-lint playbooks/
	yamllint playbooks/ manifests/

syntax-check: ## Syntax check all top-level playbooks
	@for pb in playbooks/*.yml playbooks/kubernetes/*.yml; do \
		echo "Checking: $$pb"; \
		ansible-playbook -i $(INVENTORY) $$pb --syntax-check; \
	done

check: ## Dry-run the full K8s stack playbook
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check

ping: ## Ping all hosts in inventory
	ansible -i $(INVENTORY) all -m ansible.builtin.ping
```

### 4. Create `.pre-commit-config.yaml`

```yaml
# .pre-commit-config.yaml
---
repos:
  - repo: https://github.com/ansible/ansible-lint
    rev: v24.12.2  # pin to stable version
    hooks:
      - id: ansible-lint
        args: [--profile, production]

  - repo: https://github.com/adrienverge/yamllint
    rev: v1.35.1
    hooks:
      - id: yamllint
        args: [-c, .yamllint.yml]
```

### 5. Fix Existing Lint Violations

Run `make lint` and fix all reported violations. Expected categories:

- `no-changed-when`: Add `changed_when: false` to read-only `shell`/`command` tasks
- `yaml[truthy]`: Replace bare `yes`/`no` with `true`/`false` where not already done
- `yaml[indentation]`: Fix any 4-space indented blocks
- `fqcn[action-core]`: Qualify any remaining short module names (partially done in codebase)
- `name[casing]`: Ensure all task names start with uppercase

Run iteratively until `make lint` exits 0.

### 6. Update CLAUDE.md

Add to the `## Commands` section:

```markdown
- Lint all playbooks: `make lint`
- Syntax check all playbooks: `make syntax-check`
- Dry-run full K8s stack: `make check`
- Ping all hosts: `make ping`
```

---

## Verification

```bash
# All pass with exit 0
make lint
make syntax-check

# Pre-commit hooks fire on staged .yml files
git add playbooks/kubernetes/k8s.up.yml
pre-commit run --files playbooks/kubernetes/k8s.up.yml
```

---

## Subtasks

- [ ] Create `.ansible-lint`
- [ ] Create `.yamllint.yml`
- [ ] Create `Makefile`
- [ ] Create `.pre-commit-config.yaml`
- [ ] Fix lint violations in `playbooks/` (batch by category)
- [ ] Update `CLAUDE.md`
- [ ] Install pre-commit hooks: `pre-commit install`
