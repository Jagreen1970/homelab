# Task 08 — Create Obsidian Reference Notes: Steps 01–06

## Status: TODO
## Priority: MEDIUM
## Prereqs: task-05, task-07

## Summary
Create a curated reference note in `Homelab/Tutorial/` for each of Steps 01–06.
These are not mirrors of the tutorial files — they are quick-reference cards containing
the most lookup-worthy information: key concepts, exact commands, gotchas, and links
to related Obsidian notes (Components, ADRs).

## Reference note template
```markdown
# Step NN — Title

**Covers**: one-line summary
**Source**: `tutorial/NN-filename.md` in homelab repo
**Playbooks**: `playbooks/<relevant.yml>`
**Related**: [[Components/X]], [[Architecture/Decisions/ADR-NNN-title|ADR-NNN]]

---

## Key Concepts
- bullet list of non-obvious concepts this step introduces

## Quick Reference
\`\`\`bash
# most commonly looked-up commands for this step
\`\`\`

## Gotchas
- Known prerequisites or pitfalls not obvious from the tutorial text
```

## Files to create
| File | Key content to include |
|------|----------------------|
| `Homelab/Tutorial/Step-01-project-setup.md` | Ansible config, inventory groups, module FQCN requirement |
| `Homelab/Tutorial/Step-02-user-management.md` | SSH key placement, admin_vars.yml, authorized_key module |
| `Homelab/Tutorial/Step-03-system-configuration.md` | system_vars.yml, timezone/NTP commands |
| `Homelab/Tutorial/Step-04-kubernetes-setup.md` | kubeadm init flags, flannel apply command, worker join |
| `Homelab/Tutorial/Step-05-testing.md` | kubectl health check commands, CNI test, storage test |
| `Homelab/Tutorial/Step-06-distributed-storage.md` | Longhorn install command, UI access, related [[Components/Longhorn]] |

## Steps
1. Read each corresponding tutorial file to extract key commands and gotchas
2. Create each Obsidian note using the template above
3. Link to relevant Component notes where applicable

## Subtasks
- [ ] Step-01-project-setup.md
- [ ] Step-02-user-management.md
- [ ] Step-03-system-configuration.md
- [ ] Step-04-kubernetes-setup.md
- [ ] Step-05-testing.md
- [ ] Step-06-distributed-storage.md

## Verification
- `obsidian_list_files_in_dir Homelab/Tutorial` shows all 6 step notes
- Each note has a "Related" line linking to at least one other vault note where applicable
