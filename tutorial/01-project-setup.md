# Step 1: Project Setup

This document covers the initial setup of our Ansible homelab project, including project structure, basic configuration, and first playbooks.

## Project Structure

We've organized our project with the following structure:

```
/homelab/
├── ansible_roadmap.md        # Roadmap of tasks to complete
├── inventory.yml             # Host inventory
├── LICENSE                   # MIT License
├── playbooks/                # Main playbooks directory
│   ├── admin_vars.yml        # Admin configuration variables
│   ├── prepare.up.yml        # Base system preparation
│   ├── prepare.down.yml      # Teardown for base system
│   ├── CLAUDE.md             # Style guidelines for playbooks
│   ├── user_management/      # User management playbooks
│   │   ├── user_management.yml     # Creates users, configures SSH
│   │   └── user_management.down.yml # Removes user configuration
│   └── ... other playbook directories ...
├── manifests/                # Kubernetes manifests
│   └── k8s_cluster/          # Kubernetes cluster configuration
├── ssh_keys/                 # Directory for SSH public keys (gitignored)
└── tutorial/                 # Tutorial documentation
    ├── README.md             # Overview and TOC
    ├── 01-project-setup.md   # Initial project setup
    └── 02-user-management.md # User management guide
```

This structure allows us to organize playbooks by function in their own subdirectories, improving maintainability as the project grows.

## Ansible Configuration

We've established the following standards for our playbooks:

1. **Naming**: Using snake_case for all variables, tasks, and files
2. **Structure**: Organizing related tasks into single playbooks
3. **Variables**: Centralizing admin settings in admin_vars.yml
4. **Up/Down Pairs**: Creating symmetrical playbooks for setup and teardown operations

## Initial Playbooks

Our first set of playbooks includes:

1. **prepare.up.yml**: Basic system preparation and requirements
2. **apt_upgrade.yml**: Regular system updates
3. **dist_upgrade.yml**: Full distribution upgrades
4. **k8s.up.yml**: Kubernetes cluster setup
5. **tools_up.yml**: Common tools installation

## Next Steps

Based on our roadmap, the next playbooks we plan to create are:

1. User management playbook
2. Security hardening playbook 
3. System configuration playbook

## Documentation

We're documenting our progress through this tutorial, creating a step-by-step guide for others to follow and learn from. Each major component will have its own documentation file with explanations and examples.