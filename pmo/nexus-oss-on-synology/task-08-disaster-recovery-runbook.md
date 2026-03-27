# Task 08 — Disaster Recovery & Rebuild Runbook

## Status: DONE
## Priority: MEDIUM
## Prereqs: tasks 01–07 complete

## Summary

Full ordered rebuild of the Nexus + OPNsense HAProxy + K8s integration stack from
scratch on new hardware. Follow steps top-to-bottom. Each section indicates whether
the step is manual or Ansible-automated.

---

## Automation map

| Step | How | Notes |
|---|---|---|
| Move OPNsense web GUI off port 443 | **Manual** | System → Settings → Administration → TCP Port = 8443 |
| Install os-haproxy plugin | **Manual** | System → Firmware → Plugins → Community → os-haproxy → + |
| Create Homelab CA in OPNsense | **Manual** | System → Trust → Certificate Authorities |
| Create `nexus-homelab` cert (SANs) | **Manual** | System → Trust → Certificates |
| Configure OPNsense API key | **Manual** | System → Access → Users → API keys |
| Fill Ansible Vault (OPNsense) | **Manual** | `ansible-vault edit group_vars/opnsense/vault.yml` |
| Fill Ansible Vault (Nexus) | **Manual** | `ansible-vault edit group_vars/all/nexus_vault.yml` |
| Create data directory on zaphod | **Manual** | `mkdir -p /volume1/docker/nexus/data && chown -R 200:200 ...` |
| Deploy Nexus stack | **Manual** | Via Portainer or `docker compose up -d` |
| Nexus initial setup | **Manual** | Admin password, anonymous access, Docker Bearer Token Realm |
| Create Nexus repositories (4 repos) | **Manual** | Nexus UI — see Step 6 |
| Run HAProxy + DNS playbooks | **Ansible** ✓ | `nexus.haproxy.up.yml`, `nexus.dns.up.yml` |
| Export Homelab CA cert | **Manual** | OPNsense → System → Trust → CAs → Export |
| Run K8s containerd mirror playbook | **Ansible** ✓ | `k8s.containerd-mirror.up.yml` |
| Trust Homelab CA on workstations | **Manual** | macOS: Keychain Access → System → Always Trust |
| Set Nexus Base URL | **Manual** | Nexus → Administration → System → Capabilities → Base URL |
| Run full K8s cluster setup | **Ansible** ✓ | `k8s.all.yml` |
| Deploy ArgoCD | **Ansible** ✓ | `k8s.argocd.up.yml` |
| Create `argocd-reader` user in Nexus | **Manual** | Nexus → Administration → Security → Users |
| Run ArgoCD/Nexus integration | **Ansible** ✓ | `nexus.argocd.up.yml` |

---

## Step 1 — OPNsense: free port 443 for HAProxy

**Manual — OPNsense UI**

1. System → Settings → Administration
2. Set **TCP Port** to `8443` → Save
3. OPNsense web UI is now at `https://192.168.1.1:8443`

---

## Step 2 — OPNsense: install os-haproxy plugin

**Manual — OPNsense UI**

1. System → Firmware → Plugins → **Community Plugins** tab
2. Find `os-haproxy` → click **+** to install
3. Wait for install to complete; refresh page if needed
4. Verify: Services → HAProxy should now appear in menu

> The HAProxy Ansible playbook checks that the plugin is installed and aborts if not.

---

## Step 3 — OPNsense: create Homelab CA and server certificate

**Manual — OPNsense UI**

### Certificate Authority
- System → Trust → Certificate Authorities → **Add**
  - Name: `Homelab CA`
  - Method: Create an internal Certificate Authority
  - Key type: RSA 4096 | Digest: SHA-256 | Lifetime: 3650 days
  - Country / State / City: fill as desired (these become Keychain display labels on macOS)

### Server certificate
- System → Trust → Certificates → **Add**
  - Method: Create an internal Certificate
  - CA: `Homelab CA`
  - **Descriptive name: `nexus-homelab`** ← must match `nexus_cert_name` in `opnsense_vars.yml`
  - Key type: RSA 2048 | Digest: SHA-256 | Lifetime: 825 days
  - Common name: `nexus.home`
  - SANs: `nexus.home`, `docker.home`, `docker-proxy.home`

---

## Step 4 — OPNsense: create API key + fill Ansible Vault

**Manual → Ansible**

1. System → Settings → Administration → check **Enable API** → Save
2. System → Access → Users → `admin` → API keys tab → **+** → download CSV
3. Edit the OPNsense vault:
   ```bash
   ansible-vault edit group_vars/opnsense/vault.yml --vault-password-file .vault_pass
   ```
   Set `vault_opnsense_api_key` and `vault_opnsense_api_secret` from the CSV.

---

## Step 5 — Nexus: deploy on zaphod

**Manual — zaphod SSH or Portainer**

### 5a. Create data directory
```bash
ssh zaphod
mkdir -p /volume1/docker/nexus/data
chown -R 200:200 /volume1/docker/nexus/data
```

### 5b. Deploy via Portainer
- Portainer → Stacks → **Add stack**
- Name: `nexus`
- Paste content of `manifests/nexus/docker-compose.yml`
- Click **Deploy the stack**

Or directly on zaphod:
```bash
docker compose -f manifests/nexus/docker-compose.yml up -d
```

### 5c. Wait for startup
- Portainer → Containers → nexus → Logs
- Wait for: `Started SonatypeNexusRepositoryApplication`
- Takes ~2–3 minutes on first start

---

## Step 6 — Nexus: initial setup

**Manual — Nexus UI (`http://192.168.1.207:18081`)**

### 6a. Change admin password
```bash
docker exec nexus cat /nexus-data/admin.password   # get initial password
```
- Log in → complete setup wizard → set strong admin password → save in password manager
- Disable anonymous access when prompted

### 6b. Enable Docker Bearer Token Realm
- Administration → Security → Realms
- Move **Docker Bearer Token Realm** from Available → Active → Save

### 6c. Create repositories

| Repo name | Recipe | HTTP port | Notes |
|---|---|---|---|
| `docker-hub-proxy` | docker (proxy) | 18082 | Remote: `https://registry-1.docker.io`, Docker Index: Use Docker Hub |
| `docker-lab` | docker (hosted) | 18083 | Deployment policy: Allow redeploy |
| `helm-lab` | helm (hosted) | — | Deployment policy: Allow redeploy |
| `generic-lab` | raw (hosted) | — | Deployment policy: Allow redeploy |

> Docker repo HTTP connector ports **cannot be changed** after creation — set them correctly first time.

### 6d. Create argocd-reader user (for Task 07)
- Administration → Security → Users → **Create local user**
  - User ID: `argocd-reader`, Roles: `nx-anonymous`, Status: Active
  - Save password in password manager

---

## Step 7 — Ansible: run HAProxy + DNS playbooks

```bash
ansible-galaxy collection install -r requirements.yml   # first time only

ansible-playbook -i inventory.yml \
  playbooks/opnsense/nexus.haproxy.up.yml \
  --vault-password-file .vault_pass

ansible-playbook -i inventory.yml \
  playbooks/opnsense/nexus.dns.up.yml \
  --vault-password-file .vault_pass
```

Expected: HAProxy configured with 3 backends + frontend on port 443; Unbound host
overrides for `nexus.home`, `docker.home`, `docker-proxy.home` → `192.168.1.1`.

---

## Step 8 — Export Homelab CA cert + trust on workstations

### 8a. Export CA cert
- OPNsense → System → Trust → Certificate Authorities → `Homelab CA` → **Export CA cert**
- Save as `playbooks/kubernetes/files/homelab-ca.pem`

### 8b. Trust on macOS
- Double-click `homelab-ca.pem` → opens Keychain Access → add to **System** keychain
- The cert may appear with a generic label (e.g. "DE" if CN is empty — only C/ST/L fields set)
- Find the cert in System → Certificates → right-click → Get Info → Trust → **Always Trust**
- Enter admin password to save

### 8c. Set Nexus Base URL
- Nexus → Administration → System → Capabilities → **Base URL** → `https://nexus.home` → Save

---

## Step 9 — Ansible: run K8s containerd mirror + CA trust

```bash
ansible-playbook -i inventory.yml \
  playbooks/kubernetes/k8s.containerd-mirror.up.yml \
  -e ansible_user=admin \
  --vault-password-file .vault_pass
```

> The `-e ansible_user=admin` workaround is needed if the primary SSH key uses an
> ED25519-SK hardware security key that isn't plugged in. Run `ssh-add` first.

---

## Step 10 — Ansible: build the K8s cluster

```bash
ansible-playbook -i inventory.yml \
  playbooks/kubernetes/k8s.all.yml \
  -K --vault-password-file .vault_pass
```

This runs in order: cluster init → MetalLB → cert-manager → ingress-nginx → storage
→ Longhorn → logging → tests.

After completion, add DNS entries in OPNsense Unbound for the MetalLB VIP (`10.1.1.10`):
- `longhorn.lab` → `10.1.1.10`
- `argocd.lab` → `10.1.1.10`
- `grafana.lab` → `10.1.1.10`

---

## Step 11 — Ansible: deploy ArgoCD

```bash
ansible-playbook -i inventory.yml \
  playbooks/kubernetes/k8s.argocd.up.yml \
  --vault-password-file .vault_pass
```

Get initial admin password:
```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d
```

Log in at `https://argocd.lab`, change password, delete the initial secret:
```bash
kubectl delete secret argocd-initial-admin-secret -n argocd
```

---

## Step 12 — Ansible: ArgoCD/Nexus integration

Fill the Nexus vault with the `argocd-reader` password created in Step 6d:
```bash
ansible-vault edit group_vars/all/nexus_vault.yml --vault-password-file .vault_pass
# Set vault_nexus_argocd_reader_password
```

Then run:
```bash
ansible-playbook -i inventory.yml \
  playbooks/kubernetes/nexus.argocd.up.yml \
  --vault-password-file .vault_pass
```

Verify: ArgoCD → Settings → Repositories → `homelab-nexus-helm` shows **Connected**.

---

## Automation gaps (candidates for future work)

| Gap | Effort | Notes |
|---|---|---|
| Nexus repository creation via REST API | Medium | Nexus REST API is well-documented; ~30 lines of Ansible `uri` tasks |
| OPNsense CA/cert creation | High | Requires key management in Ansible; manual is safer for PKI |
| ArgoCD initial admin password rotation | Low | Could add `argocd account update-password` step to playbook |
| Workstation CA trust | Low | `security add-trusted-cert` requires real TTY — hard to automate remotely |

---

## Acceptance criteria

- [x] Single document exists that a new engineer can follow top-to-bottom
- [x] All manual steps have explicit UI navigation paths and expected outcomes
- [x] All Ansible playbooks listed with exact run commands and prerequisites
- [x] Portainer stack definition committed to repo (`manifests/nexus/docker-compose.yml`)
