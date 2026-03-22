# Task 02 — Fix File Numbering

## Status: TODO
## Priority: HIGH — all content and Obsidian tasks depend on correct filenames
## Prereqs: task-01

## Summary
Rename the two duplicate `08-*` files to `09-` and `10-`, and fix the internal step
heading inside `08-security-hardening.md` (currently reads "Step 4"). No content changes
in this task — filenames and headings only.

## Files to rename
| Current | Target |
|---------|--------|
| `tutorial/08-network-configuration.md` | `tutorial/09-network-configuration.md` |
| `tutorial/08-security-hardening.md` | `tutorial/10-security-hardening.md` |

## Steps
1. `git mv tutorial/08-network-configuration.md tutorial/09-network-configuration.md`
2. `git mv tutorial/08-security-hardening.md tutorial/10-security-hardening.md`
3. In `tutorial/10-security-hardening.md`, fix the internal title to read "Step 10"
   (search for "Step 4" or "Step 8" near the top of the file)
4. Verify `ls tutorial/08-*` returns only `08-logging-stack.md`

## Subtasks
- [ ] Rename `08-network-configuration.md` → `09-network-configuration.md`
- [ ] Rename `08-security-hardening.md` → `10-security-hardening.md`
- [ ] Fix internal step heading in `10-security-hardening.md`

## Verification
- `ls tutorial/08-*` → only `08-logging-stack.md`
- `ls tutorial/09-*` → `09-network-configuration.md`
- `ls tutorial/10-*` → `10-security-hardening.md`
- `grep -n "Step 4" tutorial/10-security-hardening.md` → no matches
