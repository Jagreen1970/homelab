# Building a Homelab with Ansible: Step-by-Step Tutorial

This tutorial documents the process of setting up and managing a homelab environment using Ansible for automation. Each step is documented with explanations, code, and best practices to help you learn and implement a similar setup.

## Table of Contents

1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Getting Started](#getting-started)
4. [Tutorial Steps](#tutorial-steps)
   - [Step 1: Project Setup](01-project-setup.md)
   - [Step 2: User Management](02-user-management.md)
   - [Step 3: System Configuration](03-system-configuration.md) (Coming soon)
   - [Step 4: Security Hardening](04-security-hardening.md) (Coming soon)
   - [Step 5: Package Management](05-package-management.md) (Coming soon)
   - [Step 6: Network Configuration](06-network-configuration.md) (Coming soon)
   - [Step 7: Kubernetes Setup](07-kubernetes-setup.md) (Coming soon)
   - [Step 8: Storage Configuration](08-storage-configuration.md) (Coming soon)
   - [Step 9: Application Deployment](09-application-deployment.md) (Coming soon)
5. [Progress Tracking](#progress-tracking)
6. [License](#license)

## Introduction

This project aims to create a fully-automated homelab environment using Ansible playbooks to manage configuration, deploy services, and maintain the infrastructure. The tutorial is designed to be educational and practical, showing real-world examples of infrastructure as code.

## Project Structure

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
│   │   ├── user_management.up.yml     # Creates users, configures SSH
│   │   └── user_management.down.yml # Removes user configuration
│   └── ... other playbook directories ...
├── manifests/                # Kubernetes manifests
│   └── k8s_cluster/          # Kubernetes cluster configuration
├── ssh_keys/                 # Directory for SSH public keys
└── tutorial/                 # Tutorial documentation
    ├── README.md             # This file
    ├── 01-project-setup.md   # Initial project setup
    └── 02-user-management.md # User management guide
```

## Getting Started

To follow this tutorial, you'll need:
- Basic knowledge of Linux systems
- Multiple machines or VMs to serve as your homelab environment
- A control machine with Ansible installed
- An AVM FritzBox router (or similar home router with port forwarding capabilities)
- A Synology NAS (for storage and serving as a potential Docker host)

## Tutorial Steps

Each step in the tutorial is documented in its own markdown file, providing detailed explanations, code examples, and best practices. We follow a logical progression from basic system setup to advanced application deployment.

## Progress Tracking

This tutorial documents our progress as we build the homelab environment. Each step includes the challenges faced, decisions made, and solutions implemented.

## License

This project is open source under the MIT License and available to anyone who wants to learn about setting up a homelab with Ansible.