# Ansible Playbook Reliability and Validation Refactor

**Status**: IN PLANNING
**Started**: 2026-03-21
**Stream**: Ansible automation quality (distinct from K8s operational hardening)

---

## Executive Summary

The homelab Ansible project is operationally functional but the automation layer has accumulated technical debt. This plan addresses it systematically without disrupting cluster operations:

- No linting enforcement — quality is unchecked and violations accumulate
- Broad `failed_when: false` and `ignore_errors` usage silences real errors
- No `block/rescue` patterns — failures leave systems in unknown state
- No pre-flight assertions — invalid inputs aren't caught until mid-run
- No secrets management — all values in plaintext vars files
- No Ansible roles — common logic copy-pasted across playbooks
- Deprecated Ansible patterns in use (with_items, bare include:, short module names)
- No automated testing framework

**This plan is complementary to** `pmo/k8s-reliability-improvements/`, which handles K8s operational concerns (cluster upgrade, etcd backup, PDBs, Prometheus alerting). K8s and Helm component version updates are explicitly **out of scope** here — they belong as a follow-on in that stream once task-01 (K8s upgrade) completes.

---

## Goals

1. **Zero silent failures** — every error is visible and intentional
2. **Re-runnable safely** — full idempotency across all 30 playbooks
3. **Fast feedback** — lint and syntax-check run before any execution
4. **Validated outcomes** — each deployment asserts its own success
5. **Maintainable** — common logic in roles, not copy-pasted
6. **Standards-compliant** — no deprecated patterns, current Ansible idioms throughout

---

## Success Criteria

- [ ] `ansible-lint` and `yamllint` pass with zero warnings on all playbooks
- [ ] Every playbook has a pre-flight `assert` block
- [ ] No unguarded `failed_when: false` — all replaced with targeted conditions
- [ ] Every K8s component playbook ends with post-deployment validation tasks
- [ ] All sensitive values encrypted with `ansible-vault`
- [ ] All tasks have appropriate phase + component tags
- [ ] Zero deprecated Ansible patterns (`with_*`, bare `include:`, short module names)
- [ ] Molecule tests pass for all extracted roles
- [ ] Running any playbook twice reports 0 changed tasks on an unchanged system

---

## Task List

| # | File | Description | Effort | Phase |
|---|------|-------------|--------|-------|
| 01 | [task-01-standards-and-linting.md](task-01-standards-and-linting.md) | `.ansible-lint`, `.yamllint.yml`, `Makefile`, pre-commit hooks | S | 1 |
| 02 | [task-02-variable-management-and-secrets.md](task-02-variable-management-and-secrets.md) | Migrate to `group_vars/`, ansible-vault for secrets | M | 1 |
| 03 | [task-03-preflight-validation.md](task-03-preflight-validation.md) | `assert` module, reusable pre-flight includes, per-playbook guards | M | 2 |
| 04 | [task-04-error-handling-block-rescue.md](task-04-error-handling-block-rescue.md) | Replace broad `failed_when: false`, add `block/rescue/always` | L | 2 |
| 05 | [task-05-idempotency-hardening.md](task-05-idempotency-hardening.md) | Audit `shell`/`command` tasks, fix `changed_when`, add `creates:` | M | 2 |
| 06 | [task-06-post-deployment-validation.md](task-06-post-deployment-validation.md) | Standardize health checks, new `k8s.validate.yml`, `uri` smoke tests | M | 3 |
| 07 | [task-07-tagging-strategy.md](task-07-tagging-strategy.md) | Tag taxonomy (phase/component/action), apply to all tasks | S | 1 |
| 08 | [task-08-role-refactoring.md](task-08-role-refactoring.md) | Extract `common`, `k8s_node`, `k8s_addons` roles; slim orchestrators | XL | 4 |
| 09 | [task-09-ansible-deprecations.md](task-09-ansible-deprecations.md) | Fix `with_*` loops, bare `include:`, `warn: false`, short module names | M | 2 |
| 10 | [task-10-testing-framework.md](task-10-testing-framework.md) | Molecule for roles, integration test playbooks per component | L | 4 |

---

## Task Dependency Graph

```
01 (linting)         ──────────────────────────────────────┐
02 (vars/secrets)    ──────────────────────┐               │
07 (tagging)         ── depends on 01 ─────│───────────────│
                                           │               │
03 (preflight)       ── depends on 01, 02 ─│               │
04 (error handling)  ── depends on 01 ─────│               │
05 (idempotency)     ── depends on 01, 04  │               │
09 (deprecations)    ── depends on 01 ─────│               │
                                           │               │
06 (validation)      ── depends on 03, 05  │               │
                                           │               │
08 (roles)           ── depends on 01, 04, 05, 07 ─────────┘
10 (testing)         ── depends on 08
```

---

## Recommended Execution Order

### Phase 1 — Foundation *(do first; unblocks everything)*
- **Task 01**: Standards & Linting
- **Task 02**: Variable Management & Secrets
- **Task 07**: Tagging Strategy

### Phase 2 — Hardening *(core reliability improvements)*
- **Task 03**: Pre-flight Validation
- **Task 04**: Error Handling with Block/Rescue
- **Task 05**: Idempotency Hardening
- **Task 09**: Ansible Deprecations

### Phase 3 — Validation *(outcome verification)*
- **Task 06**: Post-Deployment Validation

### Phase 4 — Refactor *(structural improvements; largest scope)*
- **Task 08**: Role Refactoring
- **Task 10**: Testing Framework

---

## Critical Files Affected

| File | Tasks |
|------|-------|
| `playbooks/kubernetes/k8s.up.yml` | 03, 04, 05, 07, 08, 09 |
| `playbooks/kubernetes/k8s.all.yml` | 03, 06, 07 |
| `playbooks/kubernetes/k8s_vars.yml` | 02 |
| `playbooks/kubernetes/k8s.logging.yml` | 04, 05, 08, 09 |
| `playbooks/kubernetes/k8s.longhorn.yml` | 04, 05, 08, 09 |
| `playbooks/kubernetes/k8s.metallb.yml` | 04, 09 |
| `playbooks/kubernetes/k8s.cert-manager.yml` | 04, 06 |
| `playbooks/admin_vars.yml` | 02 |
| `playbooks/security_hardening/security_vars.yml` | 02 |
| `playbooks/system_config/system_vars.yml` | 02 |
| `CLAUDE.md` | 01, 07 |

---

## End-to-End Verification

After all tasks complete:

```bash
# 1. Lint passes
make lint

# 2. Syntax check passes
make syntax-check

# 3. Dry run succeeds
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml --check

# 4. Post-deployment validation all-green
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.validate.yml

# 5. Role tests pass
molecule test
```
