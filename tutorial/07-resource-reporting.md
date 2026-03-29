# Resource Reporting System

This tutorial explains how to use the homelab resource reporting system to gather, analyze, and display information about your homelab nodes.

## Overview

The resource reporting system consists of two main components:

1. An Ansible playbook that collects detailed information from all hosts
2. A formatting script that organizes and displays the collected data in a user-friendly format

The system collects information about:
- CPU (count, model, frequency, load)
- Memory (total, used, free, available)
- Disk usage for mounted filesystems
- Network interfaces and IP addresses
- Docker containers and images (if installed)
- Kubernetes status and resources (if installed)
- System temperature (if available)

## Running the Resource Reporter

To run the resource reporting system, follow these steps:

### 1. Run the Ansible Playbook

```bash
ansible-playbook -i inventory.yml playbooks/report_resources.yml
```

This will collect information from all hosts in your inventory and generate two report files:
- `report.txt`: A detailed report with all collected information for each host
- `resource_summary.txt`: A condensed summary of the most important metrics

### 2. Format and Display the Reports

```bash
cd playbooks
./format_resources.sh
```

This script uses terminal colors to format the report for easier reading. It displays:
1. The summary report first (for a quick overview)
2. The detailed host reports below (for in-depth information)

## Understanding the Reports

### Summary Report

The summary report provides a quick overview of your entire homelab, including:

- Basic specs for each host (CPU, RAM, disk)
- Count of specialized nodes (Kubernetes, Docker, Storage)
- Total compute capacity across all hosts

Example:
```
HOMELAB RESOURCE SUMMARY (2023-09-10)
=====================================================================

arthur (192.168.1.101):
  CPU: 4 x 2 cores
  RAM: 8.0GB total / 4.1GB free
  Disk: 400.0GB total / 350.2GB free on /

ford (192.168.1.102):
  CPU: 4 x 2 cores
  RAM: 8.0GB total / 3.8GB free
  Disk: 400.0GB total / 349.1GB free on /

trillian (192.168.1.103):
  CPU: 2 x 2 cores
  RAM: 4.0GB total / 1.5GB free
  Disk: 200.0GB total / 152.3GB free on /

disasterarea (192.168.1.100):
  CPU: 8 x 4 cores
  RAM: 16.0GB total / 10.2GB free
  Disk: 500.0GB total / 421.5GB free on /

KUBERNETES NODES: 4
DOCKER HOSTS: 4
STORAGE HOSTS: 1

TOTAL COMPUTE CAPACITY:
  CPU Cores: 64
  RAM: 36.0GB
  Disk: 1500.0GB
```

### Detailed Report

The detailed report provides comprehensive information about each host, including:

- Host identification (hostname, IP, OS version)
- Uptime and last boot time
- Detailed CPU information
- Memory allocation
- Disk usage for all mounted filesystems
- Network interfaces and IP addresses
- Docker container and image counts
- Kubernetes status and node role
- System temperature

## Customizing the Reports

You can customize the resource reporting system by:

1. Adding additional metrics to the playbook
2. Modifying the formatting script to highlight different information
3. Filtering which hosts the report runs on using Ansible inventory groups

## Troubleshooting

If you encounter issues with the resource reporting system:

1. **Permission issues**: Ensure your Ansible user has sufficient permissions on all hosts
2. **Missing commands**: Verify that all required commands (free, lscpu, etc.) are available on your hosts
3. **Formatting errors**: If the formatted output looks incorrect, try viewing the raw reports directly

## Next Steps

After analyzing your homelab resources, you might want to:

1. Identify resource bottlenecks and plan hardware upgrades
2. Balance workloads across your cluster based on available resources
3. Set up automated alerts for resource thresholds (low disk space, high CPU usage)
4. Track resource usage over time by running reports regularly

This resource reporting system gives you valuable insights into your homelab environment and helps you make informed decisions about its management and expansion.