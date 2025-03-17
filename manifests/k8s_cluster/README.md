# Kubernetes Storage Setup

This directory contains manifests for setting up storage in your Kubernetes cluster.

## Local Storage Setup

Local storage provides volumes that are mounted directly from the node's filesystem.

### Setup Steps

1. Create local storage directories on each node:

```bash
kubectl apply -f node-local-storage-setup.yaml
```

Or alternatively use the DaemonSet approach to create directories on all nodes:

```bash
kubectl apply -f daemonset-local-storage-setup.yaml
```

2. Create the local storage class:

```bash
kubectl apply -f local-storage-class.yaml
```

3. Create local persistent volumes for each node:

```bash
# Edit local-pv-example.yaml to match your node names and storage requirements
kubectl apply -f local-pv-example.yaml
```

4. Use the local storage in your applications:

```bash
kubectl apply -f local-pvc-example.yaml
```

## NFS Storage Setup (for NAS access)

NFS storage allows your pods to access storage from your NAS (zaphod).

### Configuring NFS on Synology NAS

1. Enable NFS service:
   - Log into the Synology DSM web interface
   - Go to **Control Panel** → **File Services**
   - Navigate to the **NFS** tab and check **Enable NFS**
   - Click **Apply**

2. Create a shared folder:
   - Go to **Control Panel** → **Shared Folders**
   - Click **Create** → **Create Shared Folder**
   - Enter a name (e.g., `kubernetes`)
   - Set appropriate permissions (recommended to have a dedicated user for Kubernetes)
   - Click **OK**

3. Configure NFS permissions:
   - Go to **Control Panel** → **Shared Folders**
   - Select your kubernetes folder
   - Click **Edit** → **NFS Permissions**
   - Click **Create**
   - Enter the IP range for your Kubernetes nodes (e.g., `192.168.1.0/24` or specific IPs)
   - Set the following permissions:
     - Privilege: Read/Write
     - Squash: No mapping (or Map all users to admin)
     - Security: sys
     - Enable asynchronous
   - Click **OK** and **Apply**

4. Note your export path:
   - The NFS export path is typically in the format: `/volume1/kubernetes`
   - This is the path you'll use in the `nfs-provisioner-deployment.yaml` file

5. Verify NFS access from one of your Kubernetes nodes:
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

6. Optimize NFS performance (optional):
   - In Synology DSM, go to **Control Panel** → **File Services** → **NFS**
   - Advanced Settings:
     - Enable NFSv4.1 support
     - Increase maximum number of connections if needed
   - In the NFS export settings for your kubernetes share:
     - Enable asynchronous mode for better performance (note: potential data loss during power outage)
     - Consider adjusting security settings based on your network security requirements

### Setup Steps

1. Create the RBAC resources for the NFS provisioner:

```bash
kubectl apply -f nfs-provisioner-rbac.yaml
```

2. Deploy the NFS provisioner:

```bash
# Edit nfs-provisioner-deployment.yaml to match your NAS hostname/IP and export path
kubectl apply -f nfs-provisioner-deployment.yaml
```

3. Create the NFS storage class:

```bash
kubectl apply -f nfs-provisioner-storage-class.yaml
```

4. Use NFS storage in your applications:

```bash
kubectl apply -f nfs-pvc-example.yaml
```

## Usage in Applications

When deploying applications, reference the appropriate storage class:

- For local storage: `storageClassName: local-storage`
- For NFS storage: `storageClassName: nfs-client`

Example PVC for an application:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce  # Use ReadWriteMany for NFS if sharing across pods
  storageClassName: nfs-client  # Or local-storage
  resources:
    requests:
      storage: 5Gi
```