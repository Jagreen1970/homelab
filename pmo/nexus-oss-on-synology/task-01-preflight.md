# Task 01 — Pre-flight check on zaphod

## Status: DONE
## Priority: HIGH — run first; confirms resources before committing to deployment
## Prereqs: none

## Summary
Verify zaphod has sufficient RAM and disk, confirm target ports are free, and confirm
Portainer is reachable before deploying Nexus.

## Steps

1. **SSH to zaphod** and run:
   ```bash
   # RAM: Nexus needs min 2 GB heap, 4 GB free on host recommended
   free -h

   # Disk: recommend ≥ 50 GB free for Nexus data volume
   df -h /volume1

   # Ports: confirm 18081, 18082, 18083 are free
   # Note: ss is not available on Synology DSM — use netstat
   netstat -tlnp | grep -E '18081|18082|18083'
   ```

  Results

  ```bash
  stefan@Zaphod:/$ df -h /v
  var/          var.defaults/ volume1/      volume2/
  stefan@Zaphod:/$ df -h /volume1
  Filesystem              Size  Used Avail Use% Mounted on
  /dev/mapper/cachedev_1  3.5T  960G  2.6T  27% /volume1
  stefan@Zaphod:/$ df -h /volume2
  Filesystem              Size  Used Avail Use% Mounted on
  /dev/mapper/cachedev_0  3.5T  753G  2.8T  22% /volume2

  ```

  As expected, netstat does not produce any output.

2. **Expected results**:
- `free -h`: ≥ 4 GB available
- `df -h /volume1`: ≥ 50 GB free
- Port check: no output (ports are free)

3. **Confirm Portainer** is accessible (`http://zaphod-ip:9000`) and Docker Compose
   stacks are enabled (Portainer → Stacks menu is visible)

   --> Portainer is available.

4. **Note zaphod's LAN IP** — needed for HAProxy backend config in task-05

   Zaphod's IP is noted.


## Acceptance criteria
- [x] ≥ 4 GB RAM free
- [x] ≥ 50 GB disk free on /volume1 (2.6T available)
- [x] Ports 18081, 18082, 18083 confirmed free
- [x] Portainer accessible and stacks enabled
- [x] zaphod LAN IP noted (192.168.1.207)
