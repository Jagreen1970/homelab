# Task 04 — Reclassify distributed-storage-basics.md as Appendix

## Status: TODO
## Priority: LOW
## Prereqs: task-02

## Summary
`distributed-storage-basics.md` is a ~586-line conceptual introduction to Kubernetes
storage (PV/PVC, StorageClasses, Longhorn architecture). It is not a numbered tutorial
step — it is supplementary reading. Rename it, add a header clarifying its role, and
link to it from the README and from Step 06.

## Files to rename
| Current | Target |
|---------|--------|
| `tutorial/distributed-storage-basics.md` | `tutorial/appendix-01-storage-concepts.md` |

## Steps
1. `git mv tutorial/distributed-storage-basics.md tutorial/appendix-01-storage-concepts.md`
2. Add a notice at the top of the file:
   ```
   > **Appendix A — Supplementary Reading**
   > This document covers storage concepts in depth.
   > It is not a required tutorial step — read it for background context on Step 6.
   ```
3. In `tutorial/06-distributed-storage.md`, add a "Further Reading" section at the bottom
   linking to `appendix-01-storage-concepts.md`
4. Ensure README TOC lists it under "Appendix" (covered in task-03)

## Subtasks
- [ ] Rename file with git mv
- [ ] Add appendix notice to top of file
- [ ] Add "Further Reading" link in step 06

## Verification
- `ls tutorial/distributed-storage-basics.md` → file not found
- `ls tutorial/appendix-01-storage-concepts.md` → exists
- Step 06 footer links to the appendix
