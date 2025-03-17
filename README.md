# Ansible Playbooks for my HomeLab

<!--toc:start-->
- [Ansible Playbooks for my HomeLab](#ansible-playbooks-for-my-homelab)
  - [Basic Architecture and Setup](#basic-architecture-and-setup)
    - [Prepare the hosts](#prepare-the-hosts)
    - [Install some tools](#install-some-tools)
<!--toc:end-->

## Basic Architecture and Setup

I'm using four mini PCs with a very minimalistic installation of Ubuntu Server.

I made sure that all the servers have current user created and I can log in using a temporary password. This is essential for
the first part of the setup process.

### Prepare the hosts

```bash
ansible-playbook -i inventory.yml playbooks/prepare.up.yml -K
```

### Install some tools

```bash
ansible-playbook -i inventory.yml playbooks/tools_up.yml
```
