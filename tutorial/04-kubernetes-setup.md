# Step 4: Kubernetes Setup

This document covers setting up a complete Kubernetes cluster on our Ubuntu Mini PCs, including control plane, worker nodes, networking, and the Kubernetes dashboard.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Kubernetes Architecture Overview](#kubernetes-architecture-overview)
3. [Configuration Variables](#configuration-variables)
4. [Cluster Setup Process](#cluster-setup-process)
5. [System Preparation](#system-preparation)
6. [Container Runtime Installation](#container-runtime-installation)
7. [Kubernetes Components Installation](#kubernetes-components-installation)
8. [Control Plane Initialization](#control-plane-initialization)
9. [Worker Node Setup](#worker-node-setup)
10. [CNI Network Plugin](#cni-network-plugin)
11. [Kubernetes Dashboard](#kubernetes-dashboard)
12. [Running the Playbook](#running-the-playbook)
13. [Verifying the Cluster](#verifying-the-cluster)
14. [Next Steps](#next-steps)

## Prerequisites

Before running the Kubernetes setup playbook, you need:

1. Multiple Ubuntu machines (minimum of 2, recommended 4 or more)
2. One machine designated as the control plane (at least 2 CPU cores, 2GB RAM)
3. Worker nodes (each with at least 1 CPU core, 2GB RAM)
4. User management already set up (admin user with sudo access)
5. System configuration playbook already run
6. All nodes must have unique hostnames, static IPs, and be able to communicate with each other

## Kubernetes Architecture Overview

Our Kubernetes cluster will consist of:

1. **Control Plane Node**: Manages the cluster with components like:
   - API Server: The frontend for Kubernetes control
   - etcd: Stores all cluster data
   - Scheduler: Assigns workloads to nodes
   - Controller Manager: Maintains the desired state

2. **Worker Nodes**: Run the actual workloads with:
   - Kubelet: Ensures containers are running in a Pod
   - Kube-proxy: Maintains network rules
   - Container Runtime: Runs the containers (we use containerd)

3. **Network Layer**: Provides Pod-to-Pod communication (we use Flannel CNI)

4. **Management Tools**: Includes the Kubernetes Dashboard for easier administration

## Configuration Variables

We define our Kubernetes configuration in a central variables file. Here's our `kubernetes/k8s_vars.yml`:

```yaml
---
# Kubernetes configuration variables
k8s_version: "1.28.0"
pod_network_cidr: "10.244.0.0/16"
k8s_admin_user: "k8s-admin"
dashboard_version: "v2.7.0"
dashboard_namespace: "kubernetes-dashboard"

# Node roles
control_plane_node: "disasterarea"
worker_nodes:
  - "arthur"
  - "ford"
  - "trillian"

# Container runtime
container_runtime: "containerd"
cni_plugin: "flannel"
```

This variables file allows us to customize the Kubernetes configuration without modifying the actual playbook.

## Cluster Setup Process

Our Kubernetes setup playbook follows a structured approach:

1. Prepare the systems (disable swap, load kernel modules)
2. Install container runtime (containerd)
3. Install Kubernetes components (kubelet, kubeadm, kubectl)
4. Initialize the control plane
5. Join worker nodes to the cluster
6. Install CNI network plugin
7. Deploy Kubernetes Dashboard

## System Preparation

Kubernetes requires specific system configurations:

```yaml
- name: Disable swap
  ansible.builtin.command: swapoff -a
  changed_when: false

- name: Remove swap from fstab
  ansible.builtin.lineinfile:
    path: /etc/fstab
    regexp: '.*swap.*'
    state: absent

- name: Load required kernel modules
  ansible.builtin.command: "modprobe {{ item }}"
  loop:
    - overlay
    - br_netfilter
```

Kubernetes doesn't work well with swap enabled, as it interferes with its memory management and scheduling capabilities. We also need to ensure specific kernel modules are loaded for container networking.

## Container Runtime Installation

We use containerd as our container runtime:

```yaml
- name: Install containerd
  ansible.builtin.apt:
    name: containerd.io
    state: present
    update_cache: true

- name: Configure containerd for Kubernetes
  ansible.builtin.copy:
    dest: /etc/containerd/config.toml
    content: |
      version = 2
      
      [plugins]
        [plugins."io.containerd.grpc.v1.cri"]
          sandbox_image = "registry.k8s.io/pause:3.9"
          [plugins."io.containerd.grpc.v1.cri".containerd]
            discard_unpacked_layers = true
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
                runtime_type = "io.containerd.runc.v2"
                [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
                  SystemdCgroup = true
```

Containerd is a lightweight, high-performance container runtime that works well with Kubernetes. We configure it to use systemd cgroups for better resource management.

## Kubernetes Components Installation

Next, we install the core Kubernetes components:

```yaml
- name: Install Kubernetes components
  ansible.builtin.shell: >
    apt-get update && apt-get install -y 
    kubelet={{ k8s_version }}-* 
    kubeadm={{ k8s_version }}-* 
    kubectl={{ k8s_version }}-*
```

These components are:
- **kubelet**: The primary node agent
- **kubeadm**: Command-line tool for cluster bootstrap
- **kubectl**: Command-line client for interacting with the cluster

## Control Plane Initialization

We initialize the control plane on the designated master node:

```yaml
- name: Initialize Kubernetes cluster
  ansible.builtin.command: >
    kubeadm init
    --pod-network-cidr={{ pod_network_cidr }}
    --kubernetes-version={{ k8s_version }}
```

This sets up the control plane with the API server, etcd, scheduler, and controller manager. We specify the Pod network CIDR to ensure it doesn't conflict with our existing network.

## Worker Node Setup

After initializing the control plane, we join worker nodes to the cluster:

```yaml
- name: Join nodes to the cluster
  ansible.builtin.command: "{{ hostvars['disasterarea'].join_command }}"
```

The join command is dynamically generated by kubeadm on the control plane and contains a secure token for authentication.

## CNI Network Plugin

We install Flannel as our Container Network Interface (CNI) plugin:

```yaml
- name: Install Flannel CNI network plugin
  ansible.builtin.command: >
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

Flannel provides a simple overlay network that allows Pods to communicate across nodes.

## Kubernetes Dashboard

Finally, we deploy the Kubernetes Dashboard for easier cluster management:

```yaml
- name: Deploy Kubernetes Dashboard
  ansible.builtin.command: >
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/{{ dashboard_version }}/aio/deploy/recommended.yaml
```

We also create an admin user, generate an access token, and configure the dashboard to be accessible from outside the cluster.

## Running the Playbook

Execute the playbook with:

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.up.yml
```

This playbook will take some time to complete as it installs and configures all components across all nodes.

## Verifying the Cluster

After the playbook completes, you can verify the cluster is running correctly:

1. SSH into the control plane node
2. Run `kubectl get nodes` to see all nodes in the cluster
3. Run `kubectl get pods --all-namespaces` to see all system pods running
4. Access the dashboard using the URL and token provided

To access the dashboard:
1. Note the URL from the playbook output (https://<control_plane_ip>:<nodeport>)
2. Use the token from the `/root/dashboard-access.txt` file on the control plane node

## Next Steps

After setting up Kubernetes, our next steps will be:

1. Configuring persistent storage
2. Deploying applications
3. Setting up monitoring and logging
4. Implementing backup and recovery procedures

Remember that Kubernetes is a complex system. Start with simple deployments and gradually work your way up to more complex configurations.