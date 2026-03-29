# Homelab Resource Reporting

This playbook collects and reports on system resources across your homelab environment.

## What It Reports

The playbook collects information on:

- **CPU**: Count, model, frequency, and current load
- **Memory**: Total, used, free, and available
- **Disk**: Space usage for each mounted filesystem
- **Network**: IP addresses for each interface
- **Docker**: Container count, image count, and disk usage (if installed)
- **Kubernetes**: Version, role, and resource counts (if installed)
- **System temperature**: If available

## Usage

Run the playbook with:

```bash
ansible-playbook -i inventory.yml playbooks/report_resources.yml
```

This will generate two report files:
- `report.txt`: Detailed information for each host
- `resource_summary.txt`: Consolidated overview of all hosts

For a nicely formatted and colorized output, run:

```bash
cd playbooks
./format_resources.sh
```

## Customization

You can customize the playbook by:

- Adding more metrics to collect
- Changing the output format
- Modifying which hosts it runs on

## Example Output

```
HOMELAB RESOURCE SUMMARY (2025-03-24)
=====================================================================

arthur (192.168.1.101):
  CPU: 4 x 2 cores
  RAM: 8.0GB total / 4.1GB free
  Disk: 400.0GB total / 350.2GB free on /mnt/k8s-data

ford (192.168.1.102):
  CPU: 4 x 2 cores
  RAM: 8.0GB total / 3.8GB free
  Disk: 400.0GB total / 349.1GB free on /mnt/k8s-data

trillian (192.168.1.103):
  CPU: 2 x 2 cores
  RAM: 4.0GB total / 1.5GB free
  Disk: 200.0GB total / 152.3GB free on /mnt/k8s-data

disasterarea (192.168.1.100):
  CPU: 8 x 4 cores
  RAM: 16.0GB total / 10.2GB free
  Disk: 500.0GB total / 421.5GB free on /mnt/k8s-data

zaphod (192.168.1.200):
  CPU: 4 x 4 cores
  RAM: 8.0GB total / 2.3GB free
  Disk: 1024.0GB total / 723.8GB free on /volume1

KUBERNETES NODES: 4
DOCKER HOSTS: 5
STORAGE HOSTS: 1

TOTAL COMPUTE CAPACITY:
  CPU Cores: 66
  RAM: 44.0GB
  Disk: 2524.0GB
```