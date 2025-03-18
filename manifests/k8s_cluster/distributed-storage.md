# Distributed Storage Strategy

This document outlines recommendations for implementing distributed storage across your Kubernetes cluster nodes for workloads that require resilience and redundancy.

## Current Storage Overview

Your current storage setup includes:
- **NFS Storage**: 1TB available on zaphod (Synology NAS)
- **Local Storage**: Dedicated SSDs on worker nodes
  - trillian: 200GB SSD with ~100GB available for future allocation
  - arthur: 400GB SSD with ~200GB available for future allocation
  - ford: 400GB SSD with ~200GB available for future allocation

## Distributed Storage Options

### 1. Rook-Ceph

**Overview**: Rook is a storage orchestrator that turns distributed storage systems into self-managing, self-scaling, and self-healing storage services. Ceph is a highly scalable distributed storage solution.

**Implementation Approach**:
- Reserve 50GB from each node for a Ceph storage pool
- Use the reserved space to create a 3-node Ceph cluster with data redundancy
- Provides approximately 50GB of usable redundant storage

**Pros**:
- Full data redundancy across all nodes
- Automatic recovery from node failures
- Block, file, and object storage interfaces
- Native integration with Kubernetes

**Cons**:
- More complex to set up and maintain
- Higher CPU and memory overhead
- Requires dedicated storage on each node

### 2. Longhorn

**Overview**: Longhorn is a lightweight, reliable, and easy-to-use distributed block storage system for Kubernetes.

**Implementation Approach**:
- Reserve 50GB from each node
- Total of 150GB raw storage, can be configured for various redundancy levels
- Typically configured for 2-3 replicas for important data

**Pros**:
- Simpler to set up than Ceph
- Easy backup and restore
- Integrated disaster recovery
- Lower resource overhead than Ceph

**Cons**:
- Not as feature-rich as Ceph
- Not as mature for object storage

### 3. OpenEBS

**Overview**: OpenEBS is an easy-to-use, cloud-native storage solution that runs as a container on Kubernetes nodes.

**Implementation Approach**:
- Reserve 50GB from each node
- Use OpenEBS Jiva or cStor storage engines
- Configure replication for data redundancy

**Pros**:
- Lightweight and easy to deploy
- Multiple storage engines for different use cases
- Good for smaller deployments
- Per-application storage policies

**Cons**:
- May not scale as well for very large deployments
- Performance overhead with some storage engines

## Recommendation

For your homelab setup with 3 worker nodes, **Longhorn** offers the best balance of simplicity, reliability, and features. It would allow you to allocate a portion of each node's available space (50GB from each) to create a resilient storage pool that can survive node failures.

### Implementation Steps for Longhorn

1. Reserve 50GB from each node's available space
2. Install Longhorn:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
   ```
3. Configure the storage class and default replica count (3 for maximum resilience)
4. Create a StorageClass for distributed storage:
   ```yaml
   kind: StorageClass
   apiVersion: storage.k8s.io/v1
   metadata:
     name: longhorn-distributed
   provisioner: driver.longhorn.io
   allowVolumeExpansion: true
   parameters:
     numberOfReplicas: "3"
     staleReplicaTimeout: "30"
     fromBackup: ""
   ```

5. Use this storage class for applications requiring high availability:
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: high-availability-data
   spec:
     accessModes:
       - ReadWriteOnce
     storageClassName: longhorn-distributed
     resources:
       requests:
         storage: 10Gi
   ```

## Future Considerations

1. **Scaling**: As you add more nodes, you can expand the Longhorn storage pool
2. **Backup Integration**: Configure regular backups to your Synology NAS
3. **Monitoring**: Set up monitoring for the distributed storage system
4. **Resource Allocation**: Adjust CPU and memory limits based on observed performance