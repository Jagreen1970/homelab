# Task 06 — Content Review: Steps 07–10

## Status: TODO
## Priority: MEDIUM
## Prereqs: task-02

## Summary
Read Steps 07–10 (after renaming), identify incomplete sections, fix internal headings
(especially `10-security-hardening.md` which had "Step 4" internally), and ensure
consistent structure matching the target format from task-05.

## Files to review
| File | Known issues |
|------|-------------|
| `07-resource-reporting.md` | Confirm "Step 7" heading; check completeness |
| `08-logging-stack.md` | Confirm "Step 8" heading; check completeness |
| `09-network-configuration.md` | Confirm "Step 9" heading (was 08, renamed in task-02) |
| `10-security-hardening.md` | FIX "Step 4" internal heading → "Step 10"; check completeness |

## Steps
1. Read each file; note missing sections
2. Fix `10-security-hardening.md` internal step heading (primary fix from task-02 catchup)
3. Add missing sections per target structure from task-05
4. Ensure "Next Step" footer is present or omitted gracefully on the final step (10)

## Subtasks
- [ ] 07-resource-reporting.md — review and fix
- [ ] 08-logging-stack.md — review and fix
- [ ] 09-network-configuration.md — review and fix headings post-rename
- [ ] 10-security-hardening.md — fix "Step 4" heading; review and fix content

## Verification
- `grep "^# Step" tutorial/0[7-9]-*.md tutorial/10-*.md` — each shows "# Step N — <Title>"
- `grep "Step 4" tutorial/10-security-hardening.md` → no matches
- Step 10 does not have a broken "Next Step" link
