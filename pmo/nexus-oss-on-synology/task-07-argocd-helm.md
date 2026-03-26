# Task 07 — ArgoCD / Helm integration

## Status: TODO
## Priority: LOW
## Prereqs: task-06

## Summary
Connect the `homelab-helm` Nexus repository to ArgoCD so Helm charts stored in Nexus
can be referenced by ArgoCD Applications. Also configure the local Helm CLI for use.

---

## Steps

### 1. Create a read-only ArgoCD user in Nexus
- Administration → Security → Users → **Create local user**
  - User ID: `argocd-reader`
  - First/last name: ArgoCD Reader
  - Password: generate and save in password manager
  - Status: Active
  - Roles: assign `nx-anonymous` (read-only) or create a custom role scoped to
    `homelab-helm` repository

### 2. Connect Helm repo in ArgoCD
- ArgoCD UI → Settings → Repositories → **Connect Repo**
  - Connection method: HTTPS
  - Type: **Helm**
  - Name: `homelab-nexus-helm`
  - Project: default (or the target project)
  - Repository URL: `https://nexus.home/repository/homelab-helm/`
  - Username: `argocd-reader`
  - Password: set in step 1
  - TLS certificate verification: enabled (CA was distributed in task-06, ArgoCD pod
    inherits node trust — or upload the CA cert manually in ArgoCD cert settings)
- Click **Connect** and verify status shows green / Connected

### 3. Configure local Helm CLI (optional, for pushing charts)
```bash
helm repo add homelab https://nexus.home/repository/homelab-helm/ \
  --username admin --password <nexus-admin-password>
helm repo update
helm search repo homelab/
```

### 4. Push a test chart
```bash
helm create test-chart
helm package test-chart
curl -u admin:<password> \
  --upload-file test-chart-0.1.0.tgz \
  https://nexus.home/repository/homelab-helm/
```

### 5. Verify in ArgoCD
- ArgoCD → Settings → Repositories → click `homelab-nexus-helm` → **List apps** or
  browse — `test-chart` should appear

---

## Notes
- ArgoCD needs to trust the Homelab CA to connect to `https://nexus.home`
- If the ArgoCD pod cannot verify the cert, either:
  - Upload `homelab-ca.pem` to ArgoCD → Settings → Certificates → Add TLS certificate
  - Or ensure the ArgoCD namespace's default ServiceAccount inherits node CA trust
    (this works if containerd mirror config from task-06 already added the CA to OS trust)
- Helm push to Nexus uses `curl --upload-file` (Nexus raw push), not `helm push`
  (which requires the helm-nexus-push plugin or Nexus Pro OCI registry)

## Acceptance criteria
- [ ] `argocd-reader` user created in Nexus with read access to `homelab-helm`
- [ ] ArgoCD repo `homelab-nexus-helm` connected and green
- [ ] Test chart pushed to Nexus and visible in ArgoCD
- [ ] `helm repo add homelab ...` works from local workstation
