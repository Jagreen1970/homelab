# Task 10 — Patch Homelab/Index.md and Workstream Progress Log

## Status: TODO
## Priority: LOW
## Prereqs: task-07

## Summary
Two small Obsidian patches to close out the workstream:
1. Add a "Tutorial" section to `Homelab/Index.md` so the tutorial is discoverable from
   the master index.
2. Append a completion entry to the workstream progress log.

## Changes

### Homelab/Index.md — add Tutorial section
After the "Components" table, add:

```markdown
---

## Tutorial

- [[Tutorial/Index|Tutorial Index]] — Step-by-step homelab build walkthrough (10 steps)
```

### Homelab/Workstreams/tutorial-refactor-and-obsidian-integration.md
Append to "Progress Log":

```
**2026-03-21**: Completed workstream — tutorial renumbered, README fixed, Obsidian
Tutorial section created with 10 step reference notes.
```

## Steps
1. Use `obsidian_patch_content` to add Tutorial section to `Homelab/Index.md`
   (insert after the Components table)
2. Use `obsidian_patch_content` or `obsidian_append_content` to update progress log
   in the workstream note

## Subtasks
- [ ] Patch Homelab/Index.md — add Tutorial section
- [ ] Append to workstream progress log

## Verification
- `obsidian_get_file_contents Homelab/Index.md` contains "Tutorial" section with link
- Workstream note progress log has dated completion entry
