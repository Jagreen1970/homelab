# Task 09 — Create Obsidian Reference Notes: Steps 07–10 + Appendix

## Status: TODO
## Priority: MEDIUM
## Prereqs: task-06, task-07

## Summary
Create curated reference notes in `Homelab/Tutorial/` for Steps 07–10 and the appendix.
Same template as task-08. Steps 08–10 have rich content (logging, network, security) so
their reference notes should include the most operationally useful commands and gotchas.

## Files to create
| File | Key content to include |
|------|----------------------|
| `Homelab/Tutorial/Step-07-resource-reporting.md` | Resource reporter playbook invocation, output interpretation |
| `Homelab/Tutorial/Step-08-logging-stack.md` | Loki/Grafana install commands, Grafana NodePort access, related [[Components/Loki-Grafana]] |
| `Homelab/Tutorial/Step-09-network-configuration.md` | MetalLB config, ingress-nginx, DNS setup; related [[Components/MetalLB]], [[Architecture/Decisions/ADR-004-network-ingress-architecture\|ADR-004]] |
| `Homelab/Tutorial/Step-10-security-hardening.md` | UFW rules, SSH hardening config, fail2ban; critical: apply order to avoid locking yourself out |
| `Homelab/Tutorial/Appendix-01-storage-concepts.md` | PV/PVC lifecycle, StorageClass, Longhorn replica model — conceptual summary |

## Steps
1. Read each corresponding tutorial file to extract key commands and gotchas
2. Create each Obsidian note using the template from task-08
3. Link to Component and ADR notes where applicable (especially steps 08–10)

## Subtasks
- [ ] Step-07-resource-reporting.md
- [ ] Step-08-logging-stack.md
- [ ] Step-09-network-configuration.md
- [ ] Step-10-security-hardening.md
- [ ] Appendix-01-storage-concepts.md

## Verification
- `obsidian_list_files_in_dir Homelab/Tutorial` shows all 10 step notes + appendix + Index
- Step-10 Gotchas section mentions SSH lockout risk
- Step-09 links to [[Architecture/Decisions/ADR-004-network-ingress-architecture|ADR-004]]
