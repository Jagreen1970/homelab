# Task 03 — Update tutorial/README.md

## Status: TODO
## Priority: MEDIUM
## Prereqs: task-02

## Summary
Rewrite the Table of Contents in `tutorial/README.md` so every link points to a real file
with the correct name. The current README references steps that don't exist
(`07-application-deployment.md`, `09-security-hardening.md`, `10-package-management.md`)
and omits the actual step 07 (`07-resource-reporting.md`) and the appendix.

## Current README TOC (broken state)
- Step 7: "Application Deployment" → `07-application-deployment.md` (MISSING FILE)
- Step 8: "Network Configuration" → `08-network-configuration.md` (will be renamed to 09)
- Step 9: "Security Hardening" → `09-security-hardening.md` (will be renamed to 10)
- Step 10: "Package Management" → `10-package-management.md` (MISSING FILE)

## Target README TOC
- Step 1: Project Setup → `01-project-setup.md`
- Step 2: User Management → `02-user-management.md`
- Step 3: System Configuration → `03-system-configuration.md`
- Step 4: Kubernetes Setup → `04-kubernetes-setup.md`
- Step 5: Testing the Kubernetes Cluster → `05-testing-kubernetes-cluster.md`
- Step 6: Distributed Storage with Longhorn → `06-distributed-storage.md`
- Step 7: Resource Reporting → `07-resource-reporting.md`
- Step 8: Logging Stack (Loki + Grafana) → `08-logging-stack.md`
- Step 9: Network Configuration → `09-network-configuration.md`
- Step 10: Security Hardening → `10-security-hardening.md`
- Appendix A: Storage Concepts → `appendix-01-storage-concepts.md`

## Steps
1. Read current `tutorial/README.md`
2. Replace the Table of Contents section with the target TOC above
3. Update the Project Structure code block to reflect actual current file names
4. Remove references to "coming soon" steps that now exist

## Subtasks
- [ ] Fix TOC links
- [ ] Remove stale "coming soon" markers
- [ ] Update Project Structure block

## Verification
- Every link in the README TOC can be opened (`ls tutorial/<linked-file>` resolves)
- No broken `07-application-deployment.md` or `10-package-management.md` references remain
