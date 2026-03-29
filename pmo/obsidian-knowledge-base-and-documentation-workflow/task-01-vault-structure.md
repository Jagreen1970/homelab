# Task 01 — Vault Structure

**Status**: TODO
**Effort**: S
**Phase**: 1

## Goal

Create the skeleton `Homelab/` folder structure in Obsidian with the master index and
architecture foundation notes.

## Files to Create (via Obsidian MCP)

| Path | Purpose |
|------|---------|
| `Homelab/Index.md` | Master index: cluster state, active workstreams, component links |
| `Homelab/Architecture/Overview.md` | Hardware inventory, node roles, network layout |
| `Homelab/Architecture/Decisions/ADR-template.md` | Reusable ADR template for future decisions |

## Index.md Structure

```markdown
# Homelab — Master Index
**Cluster**: 4-node K8s (disasterarea + arthur/ford/trillian) · K8s 1.28.0 · Flannel CNI
**Last updated**: YYYY-MM-DD

## Active Workstreams
## Architecture
## Components
## Quick State (table)
```

## Acceptance Criteria

- [ ] `Homelab/Index.md` exists with correct cluster summary and working section links
- [ ] `Homelab/Architecture/Overview.md` contains hardware table and node role list
- [ ] `Homelab/Architecture/Decisions/ADR-template.md` contains the canonical ADR format

## Notes

- Use `obsidian_append_content` to create new files (creates if not exists)
- Folder structure is implicit in file paths — no need to create folders separately
