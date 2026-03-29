# Kubernetes Storage Management

This directory contains storage configurations for the homelab Kubernetes cluster.

## Storage Resources

### NFS Storage (zaphod - Synology NAS)
- **Total Available**: 1TB NFS shared folder
- **StorageClass**: `nfs-storage` (Default)
- **Provisioner**: Dynamic provisioning via NFS subdir external provisioner
- **Usage**: Shared storage needs, backups, and generally persistent data

### Local Storage (Worker Nodes)
Each worker node has dedicated local SSD storage configured with multiple volume sizes for different use cases:

#### trillian (200GB SSD)
- **StorageClass**: `local-storage-trillian`
- **Allocated Storage**:
  - Tiny Volumes: 1 × 5GB
  - Small Volumes: 1 × 10GB
  - Medium Volumes: 1 × 20GB
- **Reserved Space**:
  - ~35GB allocated for persistent volumes
  - ~65GB reserved for ephemeral storage
  - ~100GB available for future allocation

#### arthur (400GB SSD)
- **StorageClass**: `local-storage-arthur`
- **Allocated Storage**:
  - Tiny Volumes: 2 × 5GB
  - Small Volumes: 1 × 10GB
  - Medium Volumes: 1 × 20GB
  - Large Volumes: 1 × 50GB
- **Reserved Space**:
  - ~90GB allocated for persistent volumes
  - ~110GB reserved for ephemeral storage
  - ~200GB available for future allocation

#### ford (400GB SSD)
- **StorageClass**: `local-storage-ford`
- **Allocated Storage**:
  - Tiny Volumes: 2 × 5GB
  - Small Volumes: 1 × 10GB
  - Medium Volumes: 1 × 20GB
  - Large Volumes: 1 × 50GB
- **Reserved Space**:
  - ~90GB allocated for persistent volumes
  - ~110GB reserved for ephemeral storage
  - ~200GB available for future allocation

## Storage Class Selection Guide

1. **Default**: Use `nfs-storage` (NFS from zaphod) for:
   - General purpose storage
   - Shared data needs (ReadWriteMany)
   - Data that needs to survive node failures
   - Lower performance requirements

2. **Local Storage**: Use node-specific storage classes for:
   - Performance-critical workloads
   - Applications with high I/O requirements
   - Data that doesn't need to be shared between pods
   - Note: Pods using local storage will be scheduled on the specific node

3. **Volume Size Selection**:
   - **Tiny (5GB)**: Configuration files, small databases, lightweight applications
   - **Small (10GB)**: Medium-sized applications, smaller databases
   - **Medium (20GB)**: Larger applications, medium databases, analysis workloads
   - **Large (50GB)**: Data-intensive applications, larger databases

4. **Ephemeral Storage**:
   - Each node has reserved space for ephemeral storage
   - Use for temporary files, caches, and emptyDir volumes
   - Does not require PersistentVolumes or PersistentVolumeClaims

## Implementation Notes

1. Local storage is configured using StaticProvisioning with PersistentVolumes that specify node affinity
2. The DaemonSet ensures the necessary directories are created on each node
3. NFS storage uses a dynamic provisioner that creates subdirectories for each PVC
4. For workloads requiring storage, always create a PVC rather than using volumes directly
5. Additional persistent volumes can be created as needed following the established pattern

## Setup Instructions

### NFS Storage Setup

1. Configure NFS on your Synology NAS as described in `zaphod/SYNOLOGY_NFS_SETUP.md`
2. Deploy the NFS provisioner and RBAC:
   ```bash
   kubectl apply -f zaphod/nfs-provisioner-rbac.yaml
   kubectl apply -f zaphod/nfs-provisioner-deployment.yaml
   kubectl apply -f zaphod/nfs-storage-class.yaml
   ```

### Local Storage Setup

For each worker node (trillian, arthur, ford):

1. Create the storage directories on the node:
   ```bash
   # For trillian
   kubectl apply -f trillian/daemonset-local-storage-setup.yaml
   kubectl apply -f trillian/local-storage-class.yaml
   kubectl apply -f trillian/node-local-storage-setup.yaml
   
   # For arthur
   kubectl apply -f arthur/daemonset-local-storage-setup.yaml
   kubectl apply -f arthur/local-storage-class.yaml
   kubectl apply -f arthur/node-local-storage-setup.yaml
   
   # For ford
   kubectl apply -f ford/daemonset-local-storage-setup.yaml
   kubectl apply -f ford/local-storage-class.yaml
   kubectl apply -f ford/node-local-storage-setup.yaml
   ```

## Usage Examples

To create a PVC using the default NFS storage:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 10Gi
```

To create a PVC using local storage on arthur:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-local-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage-arthur
  resources:
    requests:
      storage: 5Gi  # For a tiny volume
```

## Future Expansion

When additional storage is needed, you can add more persistent volumes by:

1. Adding new PV definitions to the node-specific yaml files
2. Updating the DaemonSet to create and set permissions for new directories
3. Following the existing naming conventions (nodename-size-number)
4. Keeping track of the allocated storage in this README