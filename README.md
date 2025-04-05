# Ansible Playbooks for my HomeLab

<!--toc:start-->
- [Ansible Playbooks for my HomeLab](#ansible-playbooks-for-my-homelab)
  - [Basic Architecture and Setup](#basic-architecture-and-setup)
    - [Prepare the hosts](#prepare-the-hosts)
    - [Install some tools](#install-some-tools)
  - [Kubernetes Cluster](#kubernetes-cluster)
    - [Full Cluster Setup](#full-cluster-setup)
    - [Storage Options](#storage-options)
    - [Distributed Storage with Longhorn](#distributed-storage-with-longhorn)
  - [Testing and Validation](#testing-and-validation)
  - [Tutorials](#tutorials)
<!--toc:end-->

## Basic Architecture and Setup

I'm using four mini PCs with a very minimalistic installation of Ubuntu Server.

I made sure that all the servers have current user created and I can log in using a temporary password. This is essential for
the first part of the setup process.

### Prepare the hosts

```bash
ansible-playbook -i inventory.yml playbooks/prepare.up.yml -K
```

### Install some tools

```bash
ansible-playbook -i inventory.yml playbooks/tools_up.yml
```

## Kubernetes Cluster

The homelab includes a Kubernetes cluster with one control plane node and three worker nodes.

### Full Cluster Setup

To set up the complete Kubernetes environment with all components:

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.all.yml
```

This will:
1. Set up the basic Kubernetes cluster
2. Configure local storage
3. Deploy Longhorn distributed storage
4. Configure the logging stack
5. Run tests to verify everything works

For individual components, you can run:

```bash
# Basic Kubernetes setup
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.up.yml

# Local storage setup
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.storage.yml

# Longhorn distributed storage
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.longhorn.yml

# Logging stack
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.logging.yml
```

### Storage Options

The cluster provides multiple storage options:

1. **Local Storage**: Provided by each worker node, mainly for single-node applications
2. **NFS Storage**: Provided by the Synology NAS (zaphod), good for shared ReadWriteMany access
3. **Longhorn Distributed Storage**: High-availability storage with data replication across nodes

### Distributed Storage with Longhorn

Longhorn provides highly available persistent storage with data replication across worker nodes. To deploy and use Longhorn:

```bash
# Deploy Longhorn
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.longhorn.yml

# Check Longhorn status
/bin/bash manifests/k8s_cluster/longhorn/check-longhorn-status.sh

# Access Longhorn UI
kubectl port-forward -n longhorn-system service/longhorn-frontend 8000:80
# Then open http://localhost:8000 in your browser
```

When creating PVCs, use the `longhorn-distributed` storage class for high availability:

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

For more information, see the [Longhorn documentation](manifests/k8s_cluster/longhorn/README.md).

## Testing and Validation

To test the Kubernetes cluster and its components:

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.test.yml
```

This will test:
- Basic cluster functionality
- Network connectivity
- Local storage
- NFS storage
- Longhorn distributed storage
- Workload deployment

## Tutorials

Step-by-step tutorials for setting up and using the homelab are available in the [tutorial](tutorial/) directory.