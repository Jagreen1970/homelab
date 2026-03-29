# Synology NAS NFS Setup for Kubernetes

This document provides detailed instructions for setting up and configuring NFS on your Synology NAS (zaphod) for use with Kubernetes.

## Configuring NFS on Synology NAS

### 1. Enable NFS Service

1. Log into the Synology DSM web interface
2. Go to **Control Panel** → **File Services**
3. Navigate to the **NFS** tab and check **Enable NFS**
4. Click **Apply**

### 2. Create a Shared Folder

1. Go to **Control Panel** → **Shared Folders**
2. Click **Create** → **Create Shared Folder**
3. Enter a name (e.g., `kubernetes`)
4. Set appropriate permissions (recommended to have a dedicated user for Kubernetes)
5. Click **OK**

### 3. Configure NFS Permissions

1. Go to **Control Panel** → **Shared Folders**
2. Select your kubernetes folder
3. Click **Edit** → **NFS Permissions**
4. Click **Create**
5. Enter the IP range for your Kubernetes nodes (e.g., `192.168.1.0/24` or specific IPs)
6. Set the following permissions:
   - Privilege: Read/Write
   - Squash: No mapping (or Map all users to admin)
   - Security: sys
   - Enable asynchronous
7. Click **OK** and **Apply**

### 4. Note Your Export Path

- The NFS export path is typically in the format: `/volume1/kubernetes`
- This is the path you'll use in the `nfs-provisioner-deployment.yaml` file

### 5. Verify NFS Access

Test access from one of your Kubernetes nodes:

```bash
# Install NFS client tools if needed
sudo apt-get install nfs-common

# List NFS exports from your Synology
showmount -e zaphod

# Test mount
sudo mkdir -p /mnt/test
sudo mount -t nfs zaphod:/volume1/kubernetes /mnt/test

# Check if you can write to it
sudo touch /mnt/test/test_file

# Unmount after testing
sudo umount /mnt/test
```

### 6. Optimize NFS Performance (Optional)

- In Synology DSM, go to **Control Panel** → **File Services** → **NFS**
- Advanced Settings:
  - Enable NFSv4.1 support
  - Increase maximum number of connections if needed
- In the NFS export settings for your kubernetes share:
  - Enable asynchronous mode for better performance (note: potential data loss during power outage)
  - Consider adjusting security settings based on your network security requirements

## Troubleshooting

### Permission Issues

If pods cannot write to the NFS volume:

1. Check the NFS permissions in Synology DSM
2. Verify that the Squash setting is appropriate (usually "No mapping" works best)
3. Try mounting the NFS share manually on a node to test access

### Connection Issues

If pods cannot connect to the NFS server:

1. Verify network connectivity between nodes and NAS
2. Check that NFS service is running on the Synology
3. Confirm that no firewall is blocking NFS ports (2049 TCP/UDP)
4. Test with `showmount -e zaphod` from a node

### Performance Issues

If NFS performance is poor:

1. Enable asynchronous mode in the NFS export settings
2. Consider using NFSv4.1 which has better performance
3. Check network performance between Kubernetes nodes and NAS
4. Consider using local storage for performance-critical workloads