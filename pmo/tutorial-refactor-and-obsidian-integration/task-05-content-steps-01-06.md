# Task 05 — Content Review: Steps 01–06

## Status: TODO
## Priority: MEDIUM
## Prereqs: task-02

## Summary
Read each of Steps 01–06, identify incomplete sections, fix internal step headings,
and ensure each file follows a consistent structure. No major rewrites — gaps should
be filled with concise accurate content matching the actual playbooks.

## Target structure per step file
```
# Step N — Title

## Overview
One paragraph: what this step does and why.

## Prerequisites
Bullet list of what must be in place before running this step.

## What You'll Build
Brief description of the end state.

## Implementation
Subsections per logical group (e.g., playbook walkthrough, key variables).

## Running the Playbook
Exact ansible-playbook command(s).

## Verification
Commands to confirm the step succeeded.

## Next Step
Link to the next tutorial file.
```

## Files to review
| File | Known issues |
|------|-------------|
| `01-project-setup.md` | Confirm "Step 1" heading; check completeness |
| `02-user-management.md` | Confirm "Step 2" heading; check completeness |
| `03-system-configuration.md` | Confirm "Step 3" heading; check completeness |
| `04-kubernetes-setup.md` | Confirm "Step 4" heading; check completeness |
| `05-testing-kubernetes-cluster.md` | Confirm "Step 5" heading; check completeness |
| `06-distributed-storage.md` | Confirm "Step 6" heading; add "Further Reading" link (task-04) |

## Steps
1. Read each file; note missing sections in the audit table above
2. Add any missing sections (stub with `_TODO_` if content is non-trivial)
3. Ensure all "Next Step" links at the bottom are correct
4. Confirm each file's top-level heading reads "Step N — Title" (not "Step 4" etc.)

## Subtasks
- [ ] 01-project-setup.md — review and fix
- [ ] 02-user-management.md — review and fix
- [ ] 03-system-configuration.md — review and fix
- [ ] 04-kubernetes-setup.md — review and fix
- [ ] 05-testing-kubernetes-cluster.md — review and fix
- [ ] 06-distributed-storage.md — review, fix, add appendix link

## Verification
- `grep "^# Step" tutorial/0[1-6]-*.md` — each shows "# Step N — <Title>"
- No "Next Step" link points to a renamed or non-existent file
