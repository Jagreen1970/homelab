# Obsidian Knowledge Base and Documentation Workflow

**Status**: DONE
**Started**: 2026-03-21
**Stream**: Project knowledge management and Claude context continuity

---

## Executive Summary

The homelab project has rich code structure but no persistent documentation layer that
survives between Claude sessions. This initiative creates an Obsidian-backed knowledge base
that Claude loads automatically at the start of every session, writes to proactively as work
progresses, and uses as a verified source of truth across conversations.

Three documentation concerns are addressed:
- **Decision log (ADRs)** — record why architectural choices were made; permanent rationale
- **Workstream progress** — mirror PMO task progress as a human-readable narrative
- **Component knowledge** — per-component notes with config, quirks, and runbooks

---

## Goals

1. **Persistent context** — Claude loads relevant Obsidian notes at every session start
2. **Decision traceability** — every architectural choice captured as an ADR
3. **Progress visibility** — workstream notes mirror pmo/ task status in human-readable form
4. **Accumulated knowledge** — component discoveries never lost between sessions
5. **Zero manual effort** — Claude writes to Obsidian automatically, not on demand

---

## Success Criteria

- [x] Homelab/ folder exists in Obsidian with correct structure
- [x] Index.md accurately reflects current cluster state
- [x] ADR-001 through ADR-003 created for existing decisions
- [x] Both active PMO workstreams mirrored in Obsidian
- [x] All 5 component skeleton notes created
- [x] CLAUDE.md updated with Obsidian documentation instructions
- [ ] Claude reads Index.md automatically at the start of a new homelab session _(verify in next session)_
- [ ] Claude creates an ADR automatically when an architectural decision is made _(verify in practice)_
- [ ] Claude appends to workstream progress log automatically when a task completes _(verify in practice)_

---

## Task List

| # | File | Description | Effort | Phase |
|---|------|-------------|--------|-------|
| 01 | [task-01-vault-structure.md](task-01-vault-structure.md) | Create Homelab/ folder structure and Index.md in Obsidian | S | 1 | DONE |
| 02 | [task-02-initial-adrs.md](task-02-initial-adrs.md) | Write ADR-001 through ADR-003 for existing decisions | M | 1 | DONE |
| 03 | [task-03-workstream-mirrors.md](task-03-workstream-mirrors.md) | Mirror both PMO plans into Obsidian workstream notes | S | 1 | DONE |
| 04 | [task-04-component-notes.md](task-04-component-notes.md) | Create skeleton notes for all 5 K8s components | S | 1 | DONE |
| 05 | [task-05-claude-md-integration.md](task-05-claude-md-integration.md) | Update CLAUDE.md with Obsidian workflow instructions | S | 2 | DONE |

---

## Task Dependency Graph

```
01 (vault structure) ─── 02 (ADRs)
                     ─── 03 (workstreams)
                     ─── 04 (components)
                                          └── 05 (CLAUDE.md)
```

---

## Recommended Execution Order

### Phase 1 — Vault Setup *(create all Obsidian content)*
- **Task 01**: Vault Structure
- **Task 02**: Initial ADRs
- **Task 03**: Workstream Mirrors
- **Task 04**: Component Notes

### Phase 2 — Integration *(activate automatic behavior)*
- **Task 05**: CLAUDE.md Integration

---

## The Three Ongoing Workflows (post-setup)

### ADR Workflow
When an architectural decision is made, Claude:
1. Creates `Homelab/Architecture/Decisions/ADR-NNN-title.md` in Obsidian
2. Fills in context, decision, consequences using the ADR template
3. Appends the ADR link to the relevant workstream note under "Decisions Made"

### Workstream Progress Workflow
When a PMO task completes, Claude:
1. Patches the checkbox in the matching Obsidian workstream note
2. Appends a dated progress entry with a brief description
3. Updates Index.md status table if workstream phase changes

### Component Knowledge Workflow
When a non-obvious discovery is made (config quirk, issue, operational procedure), Claude:
1. Appends to the relevant component note under the appropriate section
   (Configuration Notes / Known Issues / Runbook)

---

## ADR Template (canonical)

See `Homelab/Architecture/Decisions/ADR-template.md` in Obsidian.

Format:
- **Date**, **Status** (Proposed / Accepted / Deprecated / Superseded by ADR-NNN)
- **Context** — what problem prompted the decision
- **Decision** — what was chosen and alternatives considered
- **Consequences** — positive outcomes and trade-offs
- **References** — playbook and manifest paths

---

## MCP Tool → Workflow Mapping

| Tool | Used For |
|------|----------|
| `obsidian_get_file_contents` | Load context (Index, workstream, component notes) |
| `obsidian_get_recent_changes` | Session start: what changed since last time |
| `obsidian_append_content` | ADR content, progress log entries, component discoveries |
| `obsidian_patch_content` | Toggle task checkboxes, update status fields |
| `obsidian_simple_search` | Find ADR or component note by keyword |
| `obsidian_list_files_in_dir` | Browse ADRs, component notes |

---

## End-to-End Verification

After all tasks complete:
1. Open Obsidian — Homelab/ appears with all subfolders and notes
2. All internal links in Index.md resolve correctly
3. Start a new Claude session in this repo — Claude announces it loaded Obsidian context
4. Make an architectural decision — Claude creates an ADR note in Obsidian automatically
5. Complete a workstream task — Claude checks the box and appends to the progress log
