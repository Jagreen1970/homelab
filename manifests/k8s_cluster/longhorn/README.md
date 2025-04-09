# Longhorn Distributed Storage

Longhorn is a lightweight, reliable, and easy-to-use distributed block storage system for Kubernetes. This directory contains the configuration files required to deploy Longhorn in your homelab Kubernetes cluster.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Configuration Files](#configuration-files)
3. [Deployment](#deployment)
4. [Testing](#testing)
5. [Usage in Applications](#usage-in-applications)
6. [Management and Monitoring](#management-and-monitoring)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying Longhorn, ensure:

1. Your Kubernetes cluster is properly set up with at least 3 worker nodes
2. Each worker node has:
   - `open-iscsi` package installed and `iscsid` service running
   - At least 50GB of free disk space in `/mnt/k8s-data/longhorn-storage` 
   - Container runtime properly configured 
3. The deployment playbook uses Ansible Kubernetes modules so no Helm installation is required
4. The kubernetes Python module is installed automatically via pip during the k8s.up.yml playbook execution

## Configuration Files

| Filename | Description |
|----------|-------------|
| `longhorn-namespace.yaml` | Defines the `longhorn-system` namespace |
| `longhorn-values.yaml` | Helm chart values for Longhorn configuration |
| `longhorn-storage-class.yaml` | Storage class for Longhorn volumes with 3 replicas |
| `node-disk-preparation.yaml` | DaemonSet to prepare node disks |
| `example-pvc.yaml` | Example PVC using Longhorn storage |

## Deployment

To deploy Longhorn to your cluster, run:

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.longhorn.yml
```

This playbook will:

1. Install prerequisites (`open-iscsi`, `nfs-common`) on all worker nodes
2. Prepare storage directories on each node
3. Deploy Longhorn components using Helm
4. Create the Longhorn storage class
5. Run a test pod to verify functionality

## Testing

Once deployed, you can verify Longhorn is working correctly:

```bash
# Run Longhorn status check playbook
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.longhorn.status.yml

# Or use the shell script for quick checks
./manifests/k8s_cluster/longhorn/check-longhorn-status.sh

# Check the storage class
kubectl get storageclass longhorn-distributed

# Check Longhorn pods
kubectl -n longhorn-system get pods

# Check Longhorn volumes
kubectl -n longhorn-system get volumes.longhorn.io
```

## Usage in Applications

To use Longhorn storage in your application, specify the `longhorn-distributed` storage class in your PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-application-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-distributed
  resources:
    requests:
      storage: 10Gi
```

Then mount the PVC in your pod or deployment:

```yaml
volumes:
- name: data-volume
  persistentVolumeClaim:
    claimName: my-application-data
volumeMounts:
- name: data-volume
  mountPath: /data
```

## Management and Monitoring

### Accessing the Longhorn UI

There are two ways to access the Longhorn UI:

#### 1. Via Ingress (Recommended)

Access via the configured Ingress:

```
http://homelab.longhorn.local
```

Make sure to add this hostname to your hosts file:
```
<CLUSTER_IP> homelab.longhorn.local
```

Replace `<CLUSTER_IP>` with the IP address of any node in your cluster.

#### 2. Via Port Forwarding

Alternatively, you can use port forwarding:

```bash
kubectl port-forward -n longhorn-system service/longhorn-frontend 8000:80
```

Then open http://localhost:8000 in your browser.

### Monitoring Storage Health

```bash
# Check volume status
kubectl -n longhorn-system get volumes.longhorn.io

# Check node status
kubectl -n longhorn-system get nodes.longhorn.io

# Check replica status for a volume
kubectl -n longhorn-system get replicas.longhorn.io -l longhornvolume=<volume-name>
```

## Troubleshooting

### Common Issues

1. **Volumes stuck in "Attaching" state**
   - Check if `iscsid` service is running on all nodes
   - Verify network connectivity between nodes

2. **Failed to create replicas**
   - Check disk space on nodes
   - Ensure storage directories have correct permissions
   - Check Longhorn manager logs:
     ```bash
     kubectl -n longhorn-system logs -l app=longhorn-manager
     ```

3. **Performance issues**
   - Adjust resource limits in the Longhorn values file
   - Consider using faster disks for Longhorn storage

### Useful Commands

```bash
# Check Longhorn system components
kubectl -n longhorn-system get pods

# Get detailed information about a volume
kubectl -n longhorn-system describe volumes.longhorn.io <volume-name>

# Check events in the Longhorn namespace
kubectl -n longhorn-system get events

# View the logs of Longhorn manager
kubectl -n longhorn-system logs -l app=longhorn-manager

# Restart Longhorn UI if it's unresponsive
kubectl -n longhorn-system rollout restart deployment/longhorn-ui
```

For more troubleshooting information, refer to the [Longhorn documentation](https://longhorn.io/docs/1.4.1/troubleshooting/).
