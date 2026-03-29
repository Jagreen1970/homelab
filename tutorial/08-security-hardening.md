# Step 4: Security Hardening

This document covers implementing security hardening measures on our Ubuntu Mini PCs, including firewall configuration, SSH hardening, fail2ban setup, and system-level security enhancements. Understanding these security concepts is crucial for maintaining a secure homelab environment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Security Variables Configuration](#security-variables-configuration)
3. [Security Hardening Playbook Overview](#security-hardening-playbook-overview)
4. [Firewall Configuration (UFW)](#firewall-configuration-ufw)
5. [SSH Hardening In-Depth](#ssh-hardening-in-depth)
6. [Brute Force Protection with Fail2ban](#brute-force-protection-with-fail2ban)
7. [System-Level Security Enhancements](#system-level-security-enhancements)
8. [Kernel Parameter Hardening](#kernel-parameter-hardening)
9. [Running the Playbook](#running-the-playbook)
10. [Security Testing and Verification](#security-testing-and-verification)
11. [Reversibility](#reversibility)
12. [Next Steps](#next-steps)

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

# Fail2ban settings
fail2ban_enabled: true
fail2ban_services:
  - sshd

# System security settings
disable_core_dumps: true
disable_ipv6: false
```

This variables file allows us to customize the security configuration without modifying the actual playbook.

## Security Hardening Playbook Overview

Our security hardening playbook implements multiple layers of security, following the "defense in depth" principle. The playbook is placed in `playbooks/security_hardening/security_hardening.up.yml`:

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

## Firewall Configuration (UFW)

### What is UFW?

Uncomplicated Firewall (UFW) is a frontend for iptables designed to simplify the process of configuring a firewall. It provides an easy-to-use interface while still being powerful enough for most firewall configurations.

### Why Do We Need a Firewall?

A firewall is your first line of defense against network-based attacks. It controls what traffic is allowed to reach your servers, blocking potentially malicious connection attempts. In a homelab environment, it's crucial to:

1. Limit exposure to only necessary services
2. Prevent unauthorized access attempts
3. Reduce the attack surface of your systems

### Our UFW Configuration Explained

Our playbook configures UFW with a "deny by default" approach:

```yaml
- name: Set UFW default policies
  community.general.ufw:
    state: enabled
    default: "{{ security_vars.ufw_default_policy.incoming }}"
    direction: incoming
```

This task sets the default policy for incoming connections to "deny", meaning any connection attempt that doesn't match an explicit allow rule will be rejected. This is more secure than allowing all traffic by default and trying to block specific threats.

We then explicitly allow only the services that are needed:

```yaml
- name: Allow specific ports in UFW
  community.general.ufw:
    rule: allow
    port: "{{ item.port }}"
    proto: "{{ item.proto }}"
    comment: "{{ item.comment }}"
  loop: "{{ security_vars.ufw_allowed_ports }}"
```

### Port Selection Best Practices

When deciding which ports to open in your firewall:

1. **Minimum necessary**: Only open ports that are actively needed
2. **Specific services**: Each open port should correspond to a specific service
3. **Documentation**: Comment each open port so you know its purpose
4. **Regular review**: Periodically review open ports and close any that are no longer needed

In our configuration, we're opening:
- Port 22 (SSH) for remote administration
- Ports 80/443 (HTTP/HTTPS) for web services

You should customize this list based on the specific services your homelab will run.

## SSH Hardening In-Depth

### Why SSH Security Matters

SSH (Secure Shell) is the primary method for remote administration of Linux servers. Since it provides administrative access, it's a prime target for attackers. A compromised SSH connection could give an attacker complete control over your system.

### Key SSH Hardening Measures Explained

Our playbook applies several important SSH hardening measures:

#### 1. Disable Root Login

```yaml
permit_root_login: "no"
```

**Why it matters**: The root account has unlimited privileges on a Linux system. If an attacker can log in directly as root, they immediately gain full control. By disabling root login, we force administrators to log in as regular users first and then use sudo for privileged operations, adding an extra authentication layer.

#### 2. Enforce Key-Based Authentication

```yaml
password_authentication: "no"
pubkey_authentication: "yes"
```

**Why it matters**: Password-based authentication is vulnerable to brute force attacks. SSH keys are much more secure because:
- They're typically 2048 bits or longer, making brute force attacks practically impossible
- The private key never leaves the client machine
- Even if a server is compromised, the attacker can't use its keys to access other servers

#### 3. Limit Authentication Attempts

```yaml
max_auth_tries: 3
```

**Why it matters**: This setting limits how many failed authentication attempts are allowed before SSH disconnects. This helps mitigate brute force attacks by making them much slower and more likely to be detected.

#### 4. Disable Unnecessary SSH Features

```yaml
x11_forwarding: "no"
allow_agent_forwarding: "no"
allow_tcp_forwarding: "no"
```

**Why it matters**: Each enabled feature increases the potential attack surface. X11 forwarding allows GUI applications but can be exploited for unauthorized access. Agent forwarding allows using your local SSH keys on the remote server but can lead to key theft if the server is compromised. TCP forwarding can be used to bypass firewall restrictions.

#### 5. Set Session Timeouts

```yaml
client_alive_interval: 300
client_alive_count_max: 2
```

**Why it matters**: These settings ensure that abandoned or idle SSH sessions are automatically terminated after a period of inactivity (in this case, about 10 minutes). This reduces the window of opportunity for an attacker to hijack an existing session.

## Brute Force Protection with Fail2ban

### What is Fail2ban?

Fail2ban is a service that monitors log files for signs of malicious activity, such as repeated failed login attempts, and automatically updates firewall rules to block the source of those attempts for a specified period of time.

### Why You Need Fail2ban

Even with key-based authentication and other SSH hardening measures, attackers can still attempt to brute force your SSH service. These attempts:

1. Consume system resources
2. Fill up log files
3. Potentially exploit unknown vulnerabilities

Fail2ban provides dynamic protection by temporarily blocking IPs that show malicious behavior.

### How Our Fail2ban Configuration Works

The playbook installs and configures Fail2ban:

```yaml
- name: Install Fail2ban
  ansible.builtin.apt:
    name: fail2ban
    state: present
  when: security_vars.fail2ban_enabled | bool
```

We then configure it using a Jinja2 template:

```yaml
- name: Configure Fail2ban for SSH
  ansible.builtin.template:
    src: ../templates/jail.local.j2
    dest: /etc/fail2ban/jail.local
    owner: root
    group: root
    mode: 0644
  when: security_vars.fail2ban_enabled | bool
  notify: Restart Fail2ban service
```

Our jail.local.j2 template contains:

```
[DEFAULT]
# Ban hosts for one hour
bantime  = 3600
findtime  = 600
maxretry = 3
banaction = iptables-multiport

# Override /etc/fail2ban/jail.d/00-firewalld.conf
banaction = iptables-multiport

{% for service in security_vars.fail2ban_services %}
[{{ service }}]
enabled = true
{% endfor %}
```

### Key Fail2ban Settings Explained

- **bantime**: How long (in seconds) an IP is banned. We set this to 3600 seconds (1 hour).
- **findtime**: The time window (in seconds) Fail2ban looks at for failed attempts. We set this to 600 seconds (10 minutes).
- **maxretry**: Number of failures allowed within the findtime before an IP is banned. We set this to 3.

With these settings, if an IP address has 3 failed SSH authentication attempts within 10 minutes, it will be banned for 1 hour.

## System-Level Security Enhancements

Beyond network and service-specific hardening, we also implement system-level security enhancements:

### 1. Disable Core Dumps

```yaml
- name: Disable core dumps
  ansible.builtin.lineinfile:
    path: /etc/security/limits.conf
    line: "* hard core 0"
    state: present
  when: security_vars.disable_core_dumps | bool
```

**Why it matters**: Core dumps are created when a program crashes and can contain sensitive information, including passwords or encryption keys that were in memory. Disabling them prevents this information from being written to disk.

### 2. IPv6 Configuration

```yaml
- name: Disable IPv6 if configured
  ansible.posix.sysctl:
    name: "{{ item }}"
    value: "1"
    state: present
    sysctl_set: yes
    reload: yes
  with_items:
    - net.ipv6.conf.all.disable_ipv6
    - net.ipv6.conf.default.disable_ipv6
    - net.ipv6.conf.lo.disable_ipv6
  when: security_vars.disable_ipv6 | bool
```

**Why it matters**: If you're not using IPv6 in your network, disabling it reduces the attack surface. However, be cautious with this setting as some applications may depend on IPv6 being available, even on a local interface.

## Kernel Parameter Hardening

Kernel parameters control various aspects of the Linux kernel's behavior. Our playbook configures several parameters to enhance security:

```yaml
- name: Set kernel parameters for security
  ansible.posix.sysctl:
    name: "{{ item.key }}"
    value: "{{ item.value }}"
    state: present
    sysctl_set: yes
    reload: yes
  loop:
    - { key: "kernel.randomize_va_space", value: "2" }
    - { key: "net.ipv4.conf.all.accept_redirects", value: "0" }
    # More parameters...
```

### Key Kernel Parameters Explained

- **kernel.randomize_va_space=2**: Enables Address Space Layout Randomization (ASLR), which makes it harder for attackers to predict memory addresses when exploiting buffer overflow vulnerabilities.

- **net.ipv4.conf.all.accept_redirects=0**: Disables ICMP redirect acceptance. ICMP redirects can be used in man-in-the-middle attacks to route traffic through a malicious host.

- **net.ipv4.conf.all.secure_redirects=0**: Similar to the above, but for "secure" redirects (those from gateways listed in the default gateway list).

- **net.ipv4.conf.all.accept_source_route=0**: Disables source-routed packets, which can be used to bypass network security measures.

- **net.ipv4.icmp_echo_ignore_broadcasts=1**: Prevents the system from responding to broadcast ICMP echo requests, which can be used in "Smurf" DDoS attacks.

## Running the Playbook

Execute the playbook with:

```bash
ansible-playbook -i inventory.yml playbooks/security_hardening/security_hardening.up.yml
```

## Security Testing and Verification

After applying the security hardening, it's crucial to verify that your systems are properly secured but still functioning as expected. Here are some tests you should perform:

### 1. SSH Connectivity Test

```bash
# Should succeed with key-based authentication
ssh -i ~/.ssh/your_key admin@your-server

# Should fail
ssh admin@your-server  # Without key
ssh root@your-server   # As root
```

### 2. Port Scanning Test

Use nmap to verify that only the allowed ports are open:

```bash
nmap -sS your-server-ip
```

You should only see the ports you've explicitly allowed in your UFW configuration.

### 3. Fail2ban Test

You can test Fail2ban by deliberately triggering failed login attempts (from a different IP if possible):

```bash
# Attempt to login with incorrect password several times
ssh nonexistent-user@your-server
```

Then check if the IP was banned:

```bash
sudo fail2ban-client status sshd
```

### 4. Log Review

Regularly review your system logs for signs of attempted intrusions:

```bash
sudo grep "Failed password" /var/log/auth.log
sudo grep "POSSIBLE BREAK-IN ATTEMPT" /var/log/auth.log
```

## Reversibility

We've created a complementary `security_hardening.down.yml` playbook that can undo these security measures if needed. However, use this with caution, as it will return your systems to a less secure state.

The down playbook:
1. Removes Fail2ban
2. Resets SSH to more permissive defaults
3. Disables the UFW firewall
4. Reverts system security settings

## Next Steps

After implementing security hardening, our next steps will be:

1. Package management
2. Network configuration
3. Service deployment

Remember that security is not a one-time setup but an ongoing process. Regularly update your systems, review logs, and adjust security measures as your homelab environment evolves.