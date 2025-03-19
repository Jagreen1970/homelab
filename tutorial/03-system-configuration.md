# Step 3: System Configuration

This document covers configuring basic system settings on our Ubuntu Mini PCs, including hostname, timezone, locale, and time synchronization.

## Prerequisites

Before running the system configuration playbook, you need:

1. Ubuntu installations on your Mini PCs
2. Initial SSH access to these machines
3. User management playbook already completed (recommended)

## System Variables Configuration

We define our system configuration options in a central variables file to make the setup easily configurable. Here's our `system_vars.yml`:

```yaml
---
# System configuration variables

# Timezone settings
timezone: Europe/Berlin

# Locale settings
system_locale: en_US.UTF-8

# NTP servers
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
  - 2.pool.ntp.org
  - 3.pool.ntp.org
```

This file centralizes system configuration and can be adjusted for different environments.

## System Configuration Playbook

Our system configuration playbook handles:

1. Setting the hostname (from inventory)
2. Configuring timezone
3. Setting locale settings
4. Configuring NTP for time synchronization

The playbook is placed in `playbooks/system_config/system_config.up.yml`:

```yaml
---
# System Configuration Playbook
# This playbook configures hostname, timezone, and locale settings

- name: Configure basic system settings
  hosts: all
  become: true
  
  tasks:
    - name: Include system variables
      ansible.builtin.include_vars:
        file: system_vars.yml
        name: system_vars
  
    - name: Set hostname
      ansible.builtin.hostname:
        name: "{{ inventory_hostname }}"
        use: systemd
        
    - name: Add hostname to /etc/hosts
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "127.0.1.1 {{ inventory_hostname }}"
        regexp: '^127\.0\.1\.1'
        state: present
        
    - name: Set timezone
      community.general.timezone:
        name: "{{ system_vars.timezone }}"
        
    # Locale and NTP configuration...
```

## Running the Playbook

Execute the playbook with:

```bash
ansible-playbook -i inventory.yml playbooks/system_config/system_config.up.yml
```

Since we've already set up user management with sudo access, we don't need the `-K` flag anymore.

## Hostname Configuration

The playbook sets the hostname of each machine to match the name in your inventory file. This ensures that:

1. Each system has a recognizable, consistent hostname
2. The hostname matches what Ansible uses to reference the machine
3. The hostname is properly set in both the system and `/etc/hosts`

## Time Synchronization

Proper time synchronization is critical for a homelab, especially when running services that depend on accurate time (like Kubernetes or certificate-based authentication). Our playbook:

1. Configures systemd-timesyncd service (built into Ubuntu)
2. Sets up NTP pool servers
3. Ensures the service starts at boot

## Reversibility

We've also created a complementary `system_config.down.yml` playbook that can reset these changes if needed:

```yaml
---
# System Configuration Down Playbook
# This playbook resets hostname, timezone, and locale settings

- name: Reset system configuration
  hosts: all
  become: true
  
  tasks:
    - name: Reset hostname to default
      ansible.builtin.hostname:
        name: "ubuntu"
        use: systemd
        
    # Other reset tasks...
```

## Next Steps

After establishing basic system configuration, our next steps will be:

1. Security hardening
2. Package management
3. Network configuration