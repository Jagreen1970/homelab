# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose of this Directory

The `prompts/` directory contains context documentation and reference materials for AI assistants working on the homelab project. These files provide background information about the network topology, infrastructure, and outstanding issues.

## Documentation Files

### problems.md
Lists outstanding network and infrastructure issues (in German):
- Portainer IP configuration displaying incorrect addresses
- DHCP issues with MacBooks and QNAP NAS not receiving IP addresses from OPNsense

### topo.md
Comprehensive network topology documentation (in German):
- **Physical topology**: Room-by-room network cable distribution via basement patch panel
- **Software topology**: OPNsense firewall, DNS configuration, container infrastructure
- **Key infrastructure**:
  - Synology NAS (Zaphod): Primary container host running Portainer with Nextcloud and GitLab stacks
  - QNAP NAS (Wowbagger): Standalone file server
  - OPNsense: Firewall and DHCP server

### portainer.md
Placeholder for Portainer-specific documentation

## Related Infrastructure

### Docker Compose Stacks
The `../manifests/portainer/` directory contains docker-compose files for services running on the Synology NAS:
- **nextcloud.yml**: Complete Nextcloud stack (MariaDB, Redis, PHPMyAdmin, Nginx Proxy Manager, Nextcloud, AppAPI DSP)
  - External URL: `https://cloud.stefan-strich.de`
  - Uses Synology volume paths (`/volume1/docker/`)
- **gitlab.yml**: GitLab CE instance
  - External URL: `https://gitlab.stefan-strich.de`
  - SSH on port 2222, HTTP on port 8080

### Kubernetes Infrastructure
The parent repository also manages Kubernetes manifests in `../manifests/` for:
- ArgoCD
- GitLab Runner
- cert-manager
- Monitoring/logging stack
- Various applications (LiteLLM, Open WebUI, PostgreSQL)

## Key Network Information

- **Firewall**: OPNsense (behind Fritzbox 7490 router)
- **Container Platform**: Portainer on Synology NAS
- **Kubernetes**: Separate K8s cluster managed via manifests
- **Domain**: stefan-strich.de (for external services)
- **Timezone**: Europe/Berlin

## Usage Notes

When working on homelab tasks:
1. Reference topo.md for understanding network layout and service locations
2. Check problems.md for known issues that may be related to your task
3. Docker services run on Synology NAS (volume paths: `/volume1/docker/`)
4. Documentation is primarily in German, but code/configs use English
