# Task 07 — Create Obsidian Tutorial Index

## Status: TODO
## Priority: MEDIUM
## Prereqs: task-03

## Summary
Create `Homelab/Tutorial/Index.md` in the Obsidian vault. This is the entry point for
the Tutorial section — it lists all steps with one-line descriptions and links to the
per-step reference notes created in tasks 08 and 09.

## File to create
`Homelab/Tutorial/Index.md`

## Target content structure
```markdown
# Tutorial — Building a Homelab with Ansible

**Source**: `tutorial/` in the homelab git repo
**Purpose**: Step-by-step walkthrough of the full cluster setup

---

## Steps

| Step | Title | Topic |
|------|-------|-------|
| 01 | [[Tutorial/Step-01-project-setup\|Project Setup]] | Ansible config, inventory, repo structure |
| 02 | [[Tutorial/Step-02-user-management\|User Management]] | SSH keys, admin users |
| 03 | [[Tutorial/Step-03-system-configuration\|System Configuration]] | Timezone, locale, NTP |
| 04 | [[Tutorial/Step-04-kubernetes-setup\|Kubernetes Setup]] | Cluster init, CNI, workers |
| 05 | [[Tutorial/Step-05-testing\|Testing the Cluster]] | Health checks, networking, storage |
| 06 | [[Tutorial/Step-06-distributed-storage\|Distributed Storage]] | Longhorn installation and config |
| 07 | [[Tutorial/Step-07-resource-reporting\|Resource Reporting]] | Resource reporter playbook |
| 08 | [[Tutorial/Step-08-logging-stack\|Logging Stack]] | Loki, Promtail, Grafana |
| 09 | [[Tutorial/Step-09-network-configuration\|Network Configuration]] | Ingress, MetalLB, DNS |
| 10 | [[Tutorial/Step-10-security-hardening\|Security Hardening]] | UFW, SSH hardening, fail2ban |

## Appendices

- [[Tutorial/Appendix-01-storage-concepts\|Appendix A: Storage Concepts]] — PV/PVC, StorageClasses, Longhorn architecture
```

## Steps
1. Use Obsidian MCP `obsidian_get_file_contents` to confirm `Homelab/Tutorial/Index.md`
   does not already exist
2. Use `obsidian_append_content` or create via write to create the index note

## Subtasks
- [ ] Create `Homelab/Tutorial/Index.md`

## Verification
- Obsidian MCP: `obsidian_get_file_contents Homelab/Tutorial/Index.md` returns content
- All 10 step links and 1 appendix link are present
