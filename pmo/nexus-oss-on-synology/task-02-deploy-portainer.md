# Task 02 — Deploy Nexus OSS via Portainer

## Status: TODO
## Priority: HIGH
## Prereqs: task-01

## Summary
Create a persistent data directory on zaphod and deploy Nexus Repository OSS as a
Docker Compose stack via Portainer.

## Steps

### 1. Create data directory on zaphod
SSH to zaphod (or use File Station):
```bash
mkdir -p /volume1/docker/nexus/data
chown -R 200:200 /volume1/docker/nexus/data
```
Nexus runs as UID 200 inside the container — the host directory must be owned by that UID.

### 2. Create Portainer stack
- Open Portainer → Stacks → Add stack
- Name: `nexus`
- Paste the following Docker Compose content:

```yaml
version: "3.8"
services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    restart: unless-stopped
    ports:
      - "18081:8081"    # Nexus UI + API (internal port is always 8081)
      - "18082:18082"   # Docker Hub pull-through proxy repo
      - "18083:18083"   # Local Docker hosted repo
    volumes:
      - /volume1/docker/nexus/data:/nexus-data
    environment:
      - INSTALL4J_ADD_VM_PARAMS=-Xms2g -Xmx2g -XX:MaxDirectMemorySize=3g
```

- Click **Deploy the stack**

### 3. Watch startup
- Portainer → Containers → nexus → Logs
- Wait for: `Started Sonatype Nexus OSS` (takes 2–3 minutes on first start)
- Do NOT proceed until this log line appears

### 4. Verify
Open `http://zaphod-ip:18081` — the Nexus welcome/login page should load.

## Notes
- `-Xms2g -Xmx2g`: heap fixed at 2 GB; adjust if zaphod has ample RAM (e.g. `-Xms3g -Xmx3g`)
- Data on `/volume1/docker/nexus/data` persists across container restarts/upgrades
- Ports 18082/18083 need Docker connector configuration inside Nexus (done in task-04)

## Acceptance criteria
- [ ] `/volume1/docker/nexus/data` created, owned by UID 200
- [ ] Portainer stack `nexus` deployed and container running
- [ ] Logs show `Started Sonatype Nexus OSS`
- [ ] `http://zaphod-ip:18081` loads Nexus login page
