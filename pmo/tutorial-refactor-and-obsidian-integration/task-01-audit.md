# Task 01 — Audit Tutorial Files

## Status: TODO
## Priority: HIGH — must run first; establishes ground truth for all subsequent tasks
## Prereqs: none

## Summary
Inventory every file in `tutorial/`, document exact numbering conflicts, content gaps,
internal heading inconsistencies, and what each file covers. Output feeds directly
into task-02 and task-05/06.

## Acceptance criteria
- [ ] Full file list with line counts and topic per file
- [ ] Every numbering conflict identified (duplicate 08-* files, README mismatches)
- [ ] Internal heading issues noted per file (e.g., "Step 4" inside `08-security-hardening.md`)
- [ ] Content completeness rated per file (complete / partial / stub)
- [ ] README TOC mapped against actual files — every broken link flagged

## Steps
1. `ls -la tutorial/` — record all file names and sizes
2. For each file, read the title line and first section heading to confirm internal step number
3. Open `tutorial/README.md` — cross-reference TOC entries against actual files
4. Note any steps referenced in README that have no corresponding file
5. Record findings as comments in this task file under "Audit Results"

## Audit results
<!-- To be filled during execution -->

## Verification
- Every file in `tutorial/` appears in the audit table
- Every README TOC entry is flagged as ✓ (file exists) or ✗ (missing)
