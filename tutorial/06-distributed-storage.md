# Step 6: Distributed Storage with Longhorn

This tutorial covers setting up Longhorn as a distributed storage solution for your Kubernetes cluster. Longhorn is a lightweight, reliable, and easy-to-use distributed block storage system for Kubernetes.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Preparing the Nodes](#preparing-the-nodes)
4. [Installing Longhorn](#installing-longhorn)
5. [Testing the Installation](#testing-the-installation)
6. [Using Longhorn Storage](#using-longhorn-storage)
7. [Managing and Monitoring](#managing-and-monitoring)
8. [Troubleshooting](#troubleshooting)

## Overview

Distributed storage provides high availability for your data by replicating it across multiple nodes. In our homelab setup, we use Longhorn to create a resilient storage layer that can survive node failures.

Key benefits of Longhorn:
- Data replication across nodes
- Volume snapshots and backups
- Non-disruptive upgrades
- Simple web UI for management
- Low resource overhead

## Prerequisites

Before setting up Longhorn, ensure:

1. Your Kubernetes cluster is up and running
2. At least 3 worker nodes are available (for optimal replica distribution)
3. Each node has sufficient disk space for storage (at least 50GB recommended)
4. `open-iscsi` package is installed on all nodes

Our playbook will handle these prerequisites automatically.

## Preparing the Nodes

First, we need to prepare the worker nodes by installing required dependencies and setting up the storage directories.

```yaml
- name: Prepare worker nodes for Longhorn
  hosts: "arthur,ford,trillian"
  become: true
  remote_user: admin
  tasks:
    - name: Install required packages for Longhorn
      ansible.builtin.apt:
        name:
          - open-iscsi
          - nfs-common
        state: present
        update_cache: yes

    - name: Enable and start iscsid service
      ansible.builtin.service:
        name: iscsid
        enabled: yes
        state: started

    - name: Create Longhorn storage directory
      ansible.builtin.file:
        path: /mnt/k8s-data/longhorn-storage
        state: directory
        mode: '0700'
        owner: root
        group: root
```

## Installing Longhorn

We use Helm to deploy Longhorn on our Kubernetes cluster. Our playbook automates the following steps:

1. Add the Longhorn Helm repository
2. Create a dedicated namespace for Longhorn
3. Deploy Longhorn with customized values
4. Deploy a Longhorn storage class for persistent volumes

```yaml
- name: Add Helm repository for Longhorn
  ansible.builtin.shell: |
    helm repo add longhorn https://charts.longhorn.io || true
    helm repo update

- name: Create Longhorn namespace
  ansible.builtin.shell: |
    kubectl apply -f /home/admin/manifests/k8s_cluster/longhorn/longhorn-namespace.yaml

- name: Deploy Longhorn using Helm
  ansible.builtin.shell: |
    helm upgrade --install longhorn longhorn/longhorn \
      --namespace longhorn-system \
      --version 1.4.1 \
      --values /home/admin/manifests/k8s_cluster/longhorn/longhorn-values.yaml
```

The custom values file (`longhorn-values.yaml`) configures Longhorn with:
- 3 replicas for each volume (for maximum resilience)
- Storage path: `/mnt/k8s-data/longhorn-storage`
- Resource limits for Longhorn components

## Testing the Installation

After installation, we verify that Longhorn is working correctly by:

1. Creating a test PersistentVolumeClaim (PVC) using the Longhorn storage class
2. Deploying a test pod that writes data to this PVC
3. Checking that the data is correctly stored

```yaml
- name: Run Longhorn test pod
  ansible.builtin.shell: |
    kubectl apply -f /home/admin/manifests/k8s_cluster/test/test-longhorn-storage.yaml

- name: Check Longhorn test pod results
  ansible.builtin.shell: |
    kubectl get pod longhorn-storage-test | grep Running && \
    kubectl exec -it longhorn-storage-test -- cat /data/longhorn-test.txt
```

The test manifest creates:
- A 1GB PVC using the `longhorn-distributed` storage class
- A pod that mounts this volume and writes test data to it

## Using Longhorn Storage

To use Longhorn for your applications, create PVCs that specify the `longhorn-distributed` storage class:

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

Then, mount this PVC in your pod or deployment:

```yaml
volumes:
- name: data-volume
  persistentVolumeClaim:
    claimName: my-application-data
```

## Managing and Monitoring

Longhorn provides a web UI for managing and monitoring your storage. To access it:

```bash
kubectl port-forward -n longhorn-system service/longhorn-frontend 8000:80
```

Then open http://localhost:8000 in your browser.

From the UI, you can:
- Monitor volume health and replica status
- Create and restore snapshots
- Expand volumes
- Configure recurring backups

## Troubleshooting

Common issues and solutions:

1. **Volumes stuck in "Attaching" state**
   - Check if `iscsid` service is running on all nodes
   - Verify network connectivity between nodes

2. **Failed to create replicas**
   - Check disk space on nodes
   - Ensure the storage directories have correct permissions
   - Check Longhorn manager logs:
     ```bash
     kubectl -n longhorn-system logs -l app=longhorn-manager
     ```

3. **Performance issues**
   - Adjust resource limits in the Longhorn values file
   - Consider using faster disks for Longhorn storage

For more troubleshooting information, refer to the [Longhorn documentation](https://longhorn.io/docs/1.4.1/troubleshooting/).