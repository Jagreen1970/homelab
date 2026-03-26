# Task 05 — OPNsense HAProxy + internal CA + Unbound DNS

## Status: TODO
## Priority: HIGH
## Prereqs: task-04

## Summary
Install the OPNsense HAProxy plugin, create an internal CA and server certificate,
configure HAProxy to route three Nexus hostnames to their respective backend ports,
and add Unbound DNS host overrides for all three hostnames.

The CA certificate created here must be exported for use in task-06 (K8s node trust).

---

## Part A — Install HAProxy plugin

1. OPNsense → System → Firmware → Plugins
2. Search `os-haproxy` → click **+** to install
3. After installation: **Services → HAProxy** appears in the left navigation menu

---

## Part B — Create internal CA and server certificate

### Create the Certificate Authority
1. System → Trust → **Certificate Authorities** → Add
   - Descriptive name: `Homelab CA`
   - Method: Create an internal Certificate Authority
   - Key type: RSA, 4096 bits
   - Digest algorithm: SHA-256
   - Lifetime (days): 3650 (10 years)
   - Country, state, city: fill as desired
2. **Save**
3. **Export CA certificate** (Actions → Export CA cert) — save as `homelab-ca.pem`
   This file is needed for task-06 (K8s node distribution)

### Create the server certificate
1. System → Trust → **Certificates** → Add
   - Method: Create an internal Certificate
   - Certificate Authority: `Homelab CA`
   - Descriptive name: `nexus-homelab`
   - Key type: RSA, 2048 bits
   - Digest algorithm: SHA-256
   - Lifetime (days): 825 (max accepted by most clients)
   - Common name: `nexus.home`
   - Alternative Names — add all three:
     - DNS: `nexus.home`
     - DNS: `docker.home`
     - DNS: `docker-proxy.home`
2. **Save**

---

## Part C — Configure HAProxy backends

### Real Servers (Services → HAProxy → Settings → Real Servers)
Add one entry per Nexus port:

| Name | IP/Host | Port | Mode |
|---|---|---|---|
| `nexus_ui` | zaphod LAN IP | 18081 | active |
| `nexus_docker_proxy` | zaphod LAN IP | 18082 | active |
| `nexus_docker_local` | zaphod LAN IP | 18083 | active |

### Backend Pools (Virtual Services → Backends)
Add one pool per server:

| Pool name | Server | Health check |
|---|---|---|
| `nexus_ui_pool` | `nexus_ui` | TCP |
| `nexus_docker_proxy_pool` | `nexus_docker_proxy` | TCP |
| `nexus_docker_local_pool` | `nexus_docker_local` | TCP |

---

## Part D — Configure HAProxy frontend

### ACL Rules (Settings → Rules & Checks → Rules)
Add 3 conditions:

| Name | Expression | Value |
|---|---|---|
| `is_nexus` | Host matches | `nexus.home` |
| `is_docker_proxy` | Host matches | `docker-proxy.home` |
| `is_docker_local` | Host matches | `docker.home` |

### Frontend (Virtual Services → Frontends)
Add one HTTPS frontend:
- Name: `nexus_https`
- Listen address: `0.0.0.0:443`
- Type: HTTP / HTTPS (SSL offloading)
- Default backend pool: `nexus_ui_pool`
- SSL offloading: enabled
- Certificate: select `nexus-homelab` (created in Part B)
- Add actions:
  - If `is_nexus` → Use backend pool `nexus_ui_pool`
  - If `is_docker_proxy` → Use backend pool `nexus_docker_proxy_pool`
  - If `is_docker_local` → Use backend pool `nexus_docker_local_pool`

### Enable HAProxy
- Services → HAProxy → Settings → General → check **Enable HAProxy**
- Click **Apply** (top of page)

---

## Part E — Unbound DNS host overrides

Services → Unbound DNS → Overrides → **Host Overrides** → Add:

| Host | Domain | Type | IP |
|---|---|---|---|
| `nexus` | `home` | A | zaphod LAN IP |
| `docker` | `home` | A | zaphod LAN IP |
| `docker-proxy` | `home` | A | zaphod LAN IP |

Click **Apply** → **Reconfigure Unbound**

---

## Part F — Update Nexus Base URL

- Nexus → Administration → System → **Base URL**
- Set to: `https://nexus.home`
- Save

---

## Verify

From a workstation on the LAN:
```bash
# DNS resolves correctly
nslookup nexus.home        # → zaphod LAN IP
nslookup docker.home       # → zaphod LAN IP
nslookup docker-proxy.home # → zaphod LAN IP

# HTTPS reaches Nexus (cert untrusted until CA is installed on client)
curl -k https://nexus.home    # should return Nexus HTML
curl --cacert homelab-ca.pem https://nexus.home   # should succeed with valid cert
```

To trust the cert on your workstation: add `homelab-ca.pem` to your OS/browser trust
store (Keychain on macOS, `update-ca-certificates` on Ubuntu).

## Notes
- HAProxy terminates TLS; Nexus itself receives plain HTTP on 18081/18082/18083
- The single frontend with SNI routing means only one port (443) is needed externally
- The exported `homelab-ca.pem` is required in task-06 for K8s node trust

## Acceptance criteria
- [ ] `os-haproxy` plugin installed
- [ ] `Homelab CA` created, PEM exported as `homelab-ca.pem`
- [ ] `nexus-homelab` server cert created with all 3 SANs
- [ ] HAProxy real servers, backend pools, and frontend configured
- [ ] HAProxy enabled and running
- [ ] DNS overrides active (nslookup confirms)
- [ ] `curl -k https://nexus.home` returns Nexus HTML
- [ ] Nexus Base URL updated to `https://nexus.home`
