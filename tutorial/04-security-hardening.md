# Step 4: Security Hardening

This document covers implementing security hardening measures on our Ubuntu Mini PCs, including firewall configuration, SSH hardening, fail2ban setup, and system-level security enhancements.

## Prerequisites

Before running the security hardening playbook, you need:

1. Ubuntu installations on your Mini PCs
2. User management already set up (admin user with sudo access)
3. System configuration playbook already run

## Security Variables Configuration

We define our security settings in a central variables file that makes it easy to adjust the security posture. Here's our `security_vars.yml`:

```yaml
---
# Security hardening configuration variables

# Firewall settings
ufw_default_policy:
  incoming: deny
  outgoing: allow

ufw_allowed_ports:
  - { port: 22, proto: tcp, comment: "SSH" }
  - { port: 80, proto: tcp, comment: "HTTP" }
  - { port: 443, proto: tcp, comment: "HTTPS" }

# SSH hardening
ssh_settings:
  port: 22
  max_auth_tries: 3
  permit_root_login: "no"
  password_authentication: "no"
  pubkey_authentication: "yes"
  x11_forwarding: "no"
  use_dns: "no"
  allow_agent_forwarding: "no"
  allow_tcp_forwarding: "no"
  max_sessions: 2
  client_alive_interval: 300
  client_alive_count_max: 2

# More security settings...
```

This variables file allows us to customize the security configuration without modifying the actual playbook.

## Security Hardening Playbook

Our security hardening playbook implements multiple layers of security:

1. Firewall configuration (UFW)
2. SSH server hardening
3. Fail2ban for brute force protection
4. System-level security settings

The playbook is placed in `playbooks/security_hardening/security_hardening.up.yml`:

```yaml
---
# Security Hardening Playbook
# This playbook implements security best practices for Ubuntu servers

- name: Implement security hardening
  hosts: all
  remote_user: admin
  become: true
  
  tasks:
    - name: Include security variables
      ansible.builtin.include_vars:
        file: security_vars.yml
        name: security_vars
    
    # Firewall configuration
    - name: Install UFW (Uncomplicated Firewall)
      ansible.builtin.apt:
        name: ufw
        state: present
        update_cache: yes
    
    # More security tasks...
```

## Firewall Configuration

The playbook configures the Uncomplicated Firewall (UFW) with a "deny by default" approach:

1. Installs the UFW package
2. Sets default policies to deny incoming and allow outgoing traffic
3. Explicitly allows necessary services (SSH, HTTP, HTTPS)
4. Enables the firewall

This follows security best practices by only allowing traffic that is explicitly permitted.

## SSH Hardening

SSH is a common attack vector, so we implement several hardening measures:

1. Disable root login
2. Enforce key-based authentication (disable password authentication)
3. Disable unnecessary features (X11 forwarding, agent forwarding, TCP forwarding)
4. Set reasonable timeouts to prevent abandoned connections
5. Limit authentication attempts and sessions

## Brute Force Protection with Fail2ban

To protect against brute force attacks, we:

1. Install and configure Fail2ban
2. Set up monitoring for SSH authentication failures
3. Configure automatic IP banning for repeated failures
4. Use a Jinja2 template to generate the jail configuration

## System-Level Security

The playbook also implements system-level security measures:

1. Disables core dumps (which can contain sensitive information)
2. Configures kernel parameters to enhance security
3. Optionally disables IPv6 if not needed

## Running the Playbook

Execute the playbook with:

```bash
ansible-playbook -i inventory.yml playbooks/security_hardening/security_hardening.up.yml
```

## Security Testing

After applying the security hardening, you should verify that:

1. You can still connect to your servers via SSH using your keys
2. Attempted password logins are rejected
3. Restricted ports are not accessible
4. Multiple failed login attempts result in temporary IP banning

## Reversibility

We've also created a complementary `security_hardening.down.yml` playbook that can undo these security measures if needed. However, use this with caution, as it will return your systems to a less secure state.

## Next Steps

After implementing security hardening, our next steps will be:

1. Package management
2. Network configuration
3. Service deployment