# Task 05 — CLAUDE.md Integration

**Status**: TODO
**Effort**: S
**Phase**: 2
**Depends on**: task-01, task-02, task-03, task-04

## Goal

Add Obsidian documentation instructions to the project `CLAUDE.md` so that every future
Claude session automatically loads context and proactively writes back to Obsidian without
requiring explicit prompts.

## File to Update

`/Users/stefan/Projects/Jagreen1970/homelab/CLAUDE.md`

## Content to Add

Append a new `## Obsidian Documentation` section:

```markdown
## Obsidian Documentation

At the start of every session, read `Homelab/Index.md` from Obsidian using the obsidian
MCP tool. If the task relates to a workstream, also read the relevant
`Homelab/Workstreams/` note. Announce briefly what context was loaded.

Proactively write to Obsidian without waiting to be asked:

- **ADR**: When an architectural decision is made (tool choice, approach, version pin,
  design trade-off), create a new ADR note in `Homelab/Architecture/Decisions/` using the
  template at `Homelab/Architecture/Decisions/ADR-template.md`. Use sequential numbering
  (ADR-004, ADR-005, ...). Append the ADR link to the relevant workstream note under
  "Decisions Made".

- **Workstream progress**: When a task from `pmo/` is completed, patch the corresponding
  checkbox in the matching `Homelab/Workstreams/` note and append a dated entry to the
  "Progress Log" section: `**YYYY-MM-DD**: Completed Task NN — <brief description>.`

- **Component knowledge**: When a non-obvious discovery is made about a deployed component
  (config quirk, required pre-condition, issue + resolution, operational procedure), append
  it to the relevant `Homelab/Components/` note under the appropriate section.
```

## Acceptance Criteria

- [ ] `CLAUDE.md` contains `## Obsidian Documentation` section
- [ ] Section specifies session-start context loading behavior
- [ ] Section specifies ADR, workstream progress, and component knowledge workflows
- [ ] A new Claude session in this repo reads Obsidian context without being asked
