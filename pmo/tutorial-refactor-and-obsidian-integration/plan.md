# Tutorial Refactor & Obsidian Integration

## Goal
Fix the broken tutorial structure (duplicate numbering, README/file mismatch, stray
supplementary content) and create a curated Tutorial section in Obsidian so the tutorial
is accessible as living reference material alongside the rest of the homelab knowledge base.

## Status: IN PLANNING
**Started**: 2026-03-21
**Stream**: documentation

## Tasks (execution order)

| # | Task | Status | Prereqs | Effort |
|---|------|--------|---------|--------|
| 01 | [Audit tutorial files](task-01-audit.md) | TODO | none | S |
| 02 | [Fix file numbering](task-02-renumber-files.md) | TODO | task-01 | S |
| 03 | [Update README](task-03-update-readme.md) | TODO | task-02 | S |
| 04 | [Reclassify supplement](task-04-rationalize-supplement.md) | TODO | task-02 | S |
| 05 | [Content review Steps 01–06](task-05-content-steps-01-06.md) | TODO | task-02 | M |
| 06 | [Content review Steps 07–10](task-06-content-steps-07-10.md) | TODO | task-02 | M |
| 07 | [Obsidian Tutorial index](task-07-obsidian-tutorial-index.md) | TODO | task-03 | S |
| 08 | [Obsidian notes Steps 01–06](task-08-obsidian-steps-01-06.md) | TODO | task-05, task-07 | M |
| 09 | [Obsidian notes Steps 07–10](task-09-obsidian-steps-07-10.md) | TODO | task-06, task-07 | M |
| 10 | [Patch Homelab/Index.md](task-10-obsidian-index-update.md) | TODO | task-07 | S |

## Proposed renumbering

| Current file | Problem | Target |
|---|---|---|
| `07-resource-reporting.md` | README calls step 07 "Application Deployment" | keep; update README |
| `08-logging-stack.md` | OK (first of three 08s) | `08-logging-stack.md` |
| `08-network-configuration.md` | Duplicate 08 | `09-network-configuration.md` |
| `08-security-hardening.md` | Duplicate 08; internal heading says "Step 4" | `10-security-hardening.md` |
| `distributed-storage-basics.md` | Unnumbered conceptual supplement | `appendix-01-storage-concepts.md` |

## Execution phases

**Phase 1 — Audit** (task-01): Establish ground truth before making changes.

**Phase 2 — Structural Refactor** (tasks 02–04): Fix numbering and README first so the
content tasks operate on correctly named files.

**Phase 3 — Content Completion** (tasks 05–06): Review and improve each step's content.
Can run in parallel after task-02.

**Phase 4 — Obsidian Integration** (tasks 07–10): Build the Obsidian Tutorial section.
Tasks 08 and 09 can run in parallel after tasks 05/06 and 07 complete.

## Success criteria

- [ ] No duplicate file numbers in `tutorial/`
- [ ] `tutorial/README.md` TOC links all resolve to real files
- [ ] `distributed-storage-basics.md` renamed and linked as appendix
- [ ] All tutorial steps have consistent internal structure
- [ ] `Homelab/Tutorial/Index.md` exists in Obsidian with step list
- [ ] Obsidian step reference notes exist for all 10 steps
- [ ] `Homelab/Index.md` includes a Tutorial entry
