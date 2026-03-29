# Task 07 — ArgoCD / Helm integration

## Status: DONE
## Priority: LOW
## Prereqs: task-06

## Summary
Connect the `helm-lab` Nexus repository to ArgoCD so Helm charts stored in Nexus
can be referenced by ArgoCD Applications. CA trust and repo registration are automated
via Ansible. Nexus user creation and test chart push stay manual.

---

## Subtasks

| # | Subtask | How | Status |
|---|---|---|---|
| 07a | Create `argocd-reader` user in Nexus UI | Manual (Nexus UI) | TODO |
| 07b | Fill Nexus vault with argocd-reader password | Edit `group_vars/all/nexus_vault.yml` | TODO |
| 07c | Run `nexus.argocd.up.yml` | Ansible — CA trust + repo Secret | TODO |
| 07d | Push a test chart to `helm-lab` | Manual (helm + curl) | TODO |
| 07e | Verify repo shows green in ArgoCD | Manual verification | TODO |
| 07f | Configure local Helm CLI | Manual (helm repo add) | TODO |

---

## Subtask 07a — Create argocd-reader user in Nexus (manual)

1. Nexus → Administration → Security → Users → **Create local user**
   - User ID: `argocd-reader`
   - First name: ArgoCD, Last name: Reader
   - Password: generate and save in password manager
   - Status: Active
   - Roles: `nx-anonymous` (read-only access to all public repos)

---

## Subtask 07b — Fill Nexus vault

Edit `group_vars/all/nexus_vault.yml` and set `vault_nexus_argocd_reader_password` to
the password created in 07a, then encrypt the file:

```bash
ansible-vault encrypt group_vars/all/nexus_vault.yml
```

---

## Subtask 07c — Run nexus.argocd.up.yml

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/nexus.argocd.up.yml --ask-vault-pass
```

What it does:
1. Patches `argocd-tls-certs-cm` ConfigMap in `argocd` namespace — adds Homelab CA cert
   for `nexus.home` so ArgoCD trusts the TLS connection to Nexus
2. Creates `nexus-helm-repo` Secret in `argocd` namespace — labeled
   `argocd.argoproj.io/secret-type: repository` so ArgoCD picks it up as a Helm repo

---

## Subtask 07d — Push a test chart (manual)

```bash
helm create test-chart
helm package test-chart
curl -u admin:<nexus-admin-password> \
  --upload-file test-chart-0.1.0.tgz \
  https://nexus.home/repository/helm-lab/
rm -rf test-chart test-chart-0.1.0.tgz
```

> Nexus Helm repo uses raw push via curl (not `helm push` — that requires helm-nexus-push
> plugin or Nexus Pro OCI registry).

---

## Subtask 07e — Verify in ArgoCD

- ArgoCD UI → Settings → Repositories — `homelab-nexus-helm` should show **Connected**
- Click the repo entry → verify `test-chart` appears in the chart list

If the repo shows **Failed**, check:
1. `kubectl logs -n argocd deploy/argocd-repo-server` for TLS errors
2. `kubectl get cm argocd-tls-certs-cm -n argocd -o yaml` — confirm `nexus.home` key present
3. `kubectl get secret nexus-helm-repo -n argocd -o yaml` — confirm Secret exists with correct label

---

## Subtask 07f — Configure local Helm CLI (optional)

```bash
helm repo add homelab https://nexus.home/repository/helm-lab/ \
  --username admin --password <nexus-admin-password>
helm repo update
helm search repo homelab/
```

---

## Revert

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/nexus.argocd.down.yml
```

---

## Files

- `group_vars/all/nexus_vault.yml` — Nexus credentials vault
- `playbooks/kubernetes/nexus.argocd.up.yml`
- `playbooks/kubernetes/nexus.argocd.down.yml`

## Acceptance criteria

- [ ] 07a: `argocd-reader` user exists in Nexus with read access to `helm-lab`
- [ ] 07b: `group_vars/all/nexus_vault.yml` encrypted with argocd-reader password
- [ ] 07c: `nexus.argocd.up.yml` runs without errors
- [ ] ArgoCD repo `homelab-nexus-helm` status: Connected (green)
- [ ] Test chart visible in ArgoCD repo browser
- [ ] `helm repo add homelab ...` works from local workstation
