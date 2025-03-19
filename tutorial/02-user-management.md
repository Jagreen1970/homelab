# Step 2: User Management

This document covers setting up proper user management on our Ubuntu Mini PCs, which is an essential first step when building a homelab.

## Prerequisites

Before running the user management playbook, you need:

1. Fresh Ubuntu installations on your Mini PCs
2. SSH access to these machines (initially with default credentials)
3. SSH keys generated for your admin users
4. Basic inventory setup

## SSH Key Setup

First, we need to create SSH keys for our admin users. Create a directory structure for our keys:

```bash
mkdir -p ssh_keys
```

For each admin user, generate a key pair:

```bash
ssh-keygen -t ed25519 -C "admin@homelab" -f ssh_keys/admin
```

This will create two files:
- `ssh_keys/admin` (private key)
- `ssh_keys/admin.pub` (public key)

## Admin Variables Configuration

We define our admin users and groups in a central variables file. Here's our `admin_vars.yml`:

```yaml
---
admin_group: wheel
admin_users:
  - admin
```

This file centralizes user management configuration and can be expanded later to include more users.

## User Management Playbook

Our user management playbook handles:

1. Creating the admin group
2. Creating admin user accounts
3. Configuring sudo access without password
4. Setting up SSH key authentication
5. Securing SSH configuration

We organize related playbooks in subdirectories. For user management, we place the playbooks in `playbooks/user_management/`.

```yaml
---
# User Management Playbook
# This playbook creates admin users, configures sudo access, and sets up SSH keys

- name: Configure admin users and SSH access
  hosts: all
  become: true
  
  tasks:
    - name: Read admin_vars from file
      ansible.builtin.include_vars:
        file: ../admin_vars.yml
        name: admin_vars

    - name: Ensure admin group exists
      ansible.builtin.group:
        name: "{{ admin_vars.admin_group }}"
        state: present

    - name: Create admin users
      ansible.builtin.user:
        name: "{{ item }}"
        shell: /bin/bash
        update_password: always
        password: '!'
        groups: "{{ admin_vars.admin_group }}"
        append: true
      with_items:
        - "{{ admin_vars.admin_users }}"
      
    - name: Provide passwordless sudo rights to admin_group
      community.general.sudoers:
        name: allow-admin_users
        group: "{{ admin_vars.admin_group }}"
        state: present
        nopassword: true
        commands: ALL
        
    # SSH key setup and configuration...
```

Note that we're using the specialized `community.general.sudoers` module instead of the more generic `lineinfile` module to handle sudoers configuration, which provides better validation and security.

## Running the Playbook

Execute the playbook with:

```bash
ansible-playbook -i inventory.yml playbooks/user_management/user_management.up.yml -k -K
```

The `-k` flag prompts for the SSH password of the default user, and the `-K` flag prompts for the sudo password. Both are needed for the initial setup when the admin user doesn't exist yet.

## Security Considerations

This playbook implements several security best practices:

1. **No Root Login**: Disables SSH root login
2. **Key-Based Authentication**: Disables password authentication
3. **Sudo Configuration**: Configures sudo access for admin users
4. **User Isolation**: Creates separate users instead of using root
5. **Password Security**: We set the password to '!' which disables password login entirely, forcing SSH key authentication

## Reversibility

We've also created a complementary `user_management.down.yml` playbook that can undo all these changes if needed. This follows our pattern of creating symmetrical up/down playbook pairs for each component:

```yaml
---
# User Management Down Playbook
# This playbook removes admin users and restores SSH settings to defaults

- name: Remove admin user configuration
  hosts: all
  become: true
  
  tasks:
    - name: Read admin_vars from file
      ansible.builtin.include_vars:
        file: ../admin_vars.yml
        name: admin_vars

    - name: Remove admin users
      ansible.builtin.user:
        name: "{{ item }}"
        state: absent
        remove: true
      with_items:
        - "{{ admin_vars.admin_users }}"
    
    - name: Remove admin sudoers entry
      community.general.sudoers:
        name: allow-admin_users
        state: absent
    
    # Other cleanup tasks...
```

## Next Steps

After establishing proper user management, our next steps will be:

1. System configuration (hostname, timezone, locale)
2. Security hardening beyond SSH
3. Package management basics