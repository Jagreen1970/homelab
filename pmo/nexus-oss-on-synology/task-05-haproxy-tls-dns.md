# Task 05 — OPNsense HAProxy + internal CA + Unbound DNS

## Status: DONE
## Priority: HIGH
## Prereqs: task-04

## Summary
Configure OPNsense to route `nexus.home`, `docker.home`, and `docker-proxy.home`
to Nexus on zaphod via HAProxy (TLS termination) and Unbound DNS.

Most of this task is automated via Ansible. PKI (CA + cert) is a one-time manual step.

---

## Subtasks

| # | Subtask | How | Status |
|---|---|---|---|
| 05a | Enable OPNsense API + create API key | Manual (OPNsense UI) | DONE |
| 05b | Install `ansibleguy.opnsense` collection | `ansible-galaxy collection install -r requirements.yml` | DONE |
| 05b2 | Install `os-haproxy` plugin in OPNsense UI | System → Firmware → Plugins → os-haproxy → + | TODO |
| 05c | Fill in Ansible Vault with API credentials | Edit `group_vars/opnsense/vault.yml` | DONE |
| 05d | Create Homelab CA + `nexus-homelab` cert in OPNsense UI | Manual (System → Trust) | TODO |
| 05e | Run `nexus.haproxy.up.yml` | Ansible — installs plugin + configures HAProxy | DONE |
| 05f | Run `nexus.dns.up.yml` | Ansible — adds Unbound host overrides | DONE |
| 05g | Export CA cert + update Nexus base URL | Manual (one export + one UI step) | DONE |

---

## Subtask 05a — Enable OPNsense API (manual)

1. OPNsense → System → Settings → Administration → check **Enable API** → Save
2. System → Access → Users → `admin` → API keys tab → **+** (Add key)
3. Download the CSV — copy the key and secret for use in 05c

---

## Subtask 05b — Install Ansible collection

```bash
ansible-galaxy collection install -r requirements.yml
```

`requirements.yml` is in the repo root. It installs `ansibleguy.opnsense`.

---

## Subtask 05c — Configure Ansible Vault

Edit `group_vars/opnsense/vault.yml` and fill in the API credentials from 05a:
```bash
ansible-vault edit group_vars/opnsense/vault.yml
```

Set `vault_opnsense_api_key` and `vault_opnsense_api_secret`.
Then encrypt the file:
```bash
ansible-vault encrypt group_vars/opnsense/vault.yml
```

---

## Subtask 05d — Create CA + cert in OPNsense UI (manual)

### Certificate Authority
- System → Trust → Certificate Authorities → **Add**
  - Name: `Homelab CA`
  - Method: Create an internal Certificate Authority
  - Key: RSA 4096 | Digest: SHA-256 | Lifetime: 3650 days

### Server certificate
- System → Trust → Certificates → **Add**
  - Method: Create an internal Certificate
  - CA: `Homelab CA`
  - **Descriptive name: `nexus-homelab`** ← must match `nexus_cert_name` in opnsense_vars.yml
  - Key: RSA 2048 | Digest: SHA-256 | Lifetime: 825 days
  - Common name: `nexus.home`
  - SANs: `nexus.home`, `docker.home`, `docker-proxy.home`

---

## Subtask 05e — Run HAProxy playbook

```bash
ansible-playbook -i inventory.yml playbooks/opnsense/nexus.haproxy.up.yml --ask-vault-pass
```

What it does:
1. Installs `os-haproxy` plugin on OPNsense
2. Resolves the `nexus-homelab` TLS cert UUID from OPNsense Trust store
3. Creates 3 real servers (nexus_ui, nexus_docker_proxy, nexus_docker_local)
4. Creates 3 backend pools (mode: http, health-check enabled)
5. Creates 3 ACL rules with hostname matching + backend routing
6. Creates `nexus_https` frontend on 0.0.0.0:443 with SNI routing + TLS offload
7. Enables the HAProxy service and applies configuration (reconfigure)

> **Note**: Uses `ansible.builtin.uri` to call OPNsense REST API directly because
> `ansibleguy.opnsense` v1.2.16 has no HAProxy modules. Idempotent — skips resources
> that already exist by name.

---

## Subtask 05f — Run DNS playbook

```bash
ansible-playbook -i inventory.yml playbooks/opnsense/nexus.dns.up.yml --ask-vault-pass
```

Adds Unbound host overrides: `nexus.home`, `docker.home`, `docker-proxy.home` → **192.168.1.1 (OPNsense)**
HAProxy on OPNsense terminates TLS and proxies to zaphod (192.168.1.207) on the backend ports.

---

## Subtask 05g — Export CA cert + update Nexus base URL (manual)

1. OPNsense → System → Trust → Certificate Authorities → `Homelab CA` → **Export CA cert**
   - Save as `playbooks/kubernetes/files/homelab-ca.pem` (required for task-06)
2. Nexus → Administration → System → Base URL → set `https://nexus.home` → Save

---

## Revert

```bash
ansible-playbook -i inventory.yml playbooks/opnsense/nexus.haproxy.down.yml --ask-vault-pass
ansible-playbook -i inventory.yml playbooks/opnsense/nexus.dns.down.yml --ask-vault-pass
```

---

## Verify

```bash
nslookup nexus.home 192.168.1.1        # → 192.168.1.207
curl -k https://nexus.home             # → Nexus HTML (cert untrusted until CA installed)
curl --cacert playbooks/kubernetes/files/homelab-ca.pem https://nexus.home  # → valid cert
```

## Files
- `requirements.yml` — collection dependency
- `inventory.yml` — OPNsense host entry added
- `group_vars/opnsense/vault.yml` — API credentials (encrypt with ansible-vault)
- `playbooks/opnsense/opnsense_vars.yml` — shared vars
- `playbooks/opnsense/nexus.haproxy.up.yml` / `nexus.haproxy.down.yml`
- `playbooks/opnsense/nexus.dns.up.yml` / `nexus.dns.down.yml`

## Acceptance criteria
- [ ] 05a: OPNsense API enabled, API key created
- [ ] 05b: `ansibleguy.opnsense` collection installed
- [ ] 05c: Vault encrypted with API credentials
- [ ] 05d: `Homelab CA` and `nexus-homelab` cert created in OPNsense UI
- [ ] 05e: `nexus.haproxy.up.yml` runs without errors
- [ ] 05f: `nexus.dns.up.yml` runs without errors
- [ ] 05g: `homelab-ca.pem` exported, Nexus Base URL set to `https://nexus.home`
- [ ] `curl -k https://nexus.home` returns Nexus HTML
