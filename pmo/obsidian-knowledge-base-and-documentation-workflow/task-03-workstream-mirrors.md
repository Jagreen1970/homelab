# Task 03 — Workstream Mirrors

**Status**: TODO
**Effort**: S
**Phase**: 1
**Depends on**: task-01

## Goal

Mirror both active PMO initiatives from `pmo/` into Obsidian workstream notes. The `pmo/`
folder remains the authoritative structured source; the Obsidian notes are the human-facing
narrative layer that Claude updates as tasks progress.

## Files to Create (via Obsidian MCP)

### `Homelab/Workstreams/ansible-reliability-refactor.md`

Mirror of: `pmo/ansible-playbook-reliability-and-validation-refactor/plan.md`

Structure:
- Header: status, started date, goal summary
- Phase progress as checkboxes (10 tasks across 4 phases)
- "Decisions Made" section (ADR links added here as they're created)
- "Progress Log" section (dated entries appended as tasks complete)

### `Homelab/Workstreams/k8s-reliability-improvements.md`

Mirror of: `pmo/k8s-reliability-improvements/plan.md`

Structure:
- Header: status, goal summary
- Task list as checkboxes (6 tasks with prereqs noted)
- "Decisions Made" section
- "Progress Log" section

## Acceptance Criteria

- [ ] Both workstream notes exist in Obsidian
- [ ] All task checkboxes present and unchecked (matching current TODO status)
- [ ] "Decisions Made" and "Progress Log" sections present and empty (ready for Claude)
- [ ] Workstream notes linked from `Homelab/Index.md`

## Ongoing Maintenance

Claude updates these notes automatically:
- Checks a box when the corresponding pmo/ task moves to DONE
- Appends to "Progress Log" with date + brief description of what was completed
- Adds ADR link to "Decisions Made" when a decision is logged during the workstream
