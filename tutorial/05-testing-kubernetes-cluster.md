# Step 5: Testing Kubernetes Cluster

This document covers how to thoroughly test your Kubernetes cluster after it has been set up, ensuring that all components are working correctly before deploying production workloads.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Basic Cluster Health Checks](#basic-cluster-health-checks)
3. [Node Status Verification](#node-status-verification)
4. [Control Plane Component Tests](#control-plane-component-tests)
5. [Networking Tests](#networking-tests)
6. [Storage Tests](#storage-tests)
7. [Workload Tests](#workload-tests)
8. [Scheduled Testing with Playbooks](#scheduled-testing-with-playbooks)
9. [Troubleshooting Common Issues](#troubleshooting-common-issues)
10. [Next Steps](#next-steps)

## Prerequisites

Before testing your Kubernetes cluster, ensure:

1. Kubernetes cluster is set up (control plane and worker nodes)
2. kubectl is configured on your control node
3. You have admin access to the cluster
4. Network connectivity between all nodes

## Basic Cluster Health Checks

Start with basic health checks to verify cluster functionality:

```bash
# Check overall cluster info
kubectl cluster-info

# View the current context
kubectl config current-context

# List all nodes and their status
kubectl get nodes -o wide

# Check all namespaces for system pods
kubectl get pods --all-namespaces

# Check for any failed or pending pods
kubectl get pods --all-namespaces | grep -v "Running\|Completed"
```

These commands provide a quick overview of your cluster's health and can identify obvious issues.

## Node Status Verification

Verify each node is properly configured:

```bash
# Detailed information about nodes
kubectl describe nodes

# Check node resource usage
kubectl top nodes

# Verify kubelet status on each node
systemctl status kubelet
```

Each node should show:
- Status: Ready
- Version: matching your installed Kubernetes version
- All taints and labels properly set
- No unexpected conditions in the node description

## Control Plane Component Tests

Verify all control plane components are functioning:

```bash
# Check API Server
kubectl get --raw /healthz

# Check etcd health
kubectl -n kube-system exec -it etcd-<control-plane-name> -- etcdctl member list

# Check controller and scheduler logs
kubectl logs -n kube-system kube-controller-manager-<control-plane-name>
kubectl logs -n kube-system kube-scheduler-<control-plane-name>
```

Each control plane component should report healthy status and show no critical errors in logs.

## Networking Tests

Test Pod-to-Pod and Pod-to-Service connectivity:

```yaml
---
# test-network.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: network-test
---
apiVersion: v1
kind: Pod
metadata:
  name: network-test-1
  namespace: network-test
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: network-test-svc
  namespace: network-test
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: network-test-2
  namespace: network-test
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
```

Apply and test:

```bash
kubectl apply -f test-network.yaml

# Test Pod to Pod
kubectl exec -it -n network-test network-test-1 -- curl network-test-2

# Test Pod to Service
kubectl exec -it -n network-test network-test-1 -- curl network-test-svc
```

The network tests should succeed with HTTP 200 responses.

## Storage Tests

Test persistent storage functionality:

```yaml
---
# test-storage.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-storage  # Use your cluster's storage class
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
spec:
  containers:
  - name: storage-test
    image: busybox
    command: ["/bin/sh", "-c", "echo 'Storage test successful!' > /data/test.txt && sleep 3600"]
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-pvc
```

Apply and test:

```bash
kubectl apply -f test-storage.yaml

# Wait for the pod to start
kubectl get pods storage-test -w

# Verify data was written
kubectl exec -it storage-test -- cat /data/test.txt
```

The storage test should show "Storage test successful!" when reading the test file.

### Troubleshooting Storage Issues

If you encounter issues with storage in your Kubernetes cluster, we've created a specialized playbook to help diagnose and fix common problems. The `fix-storage.yml` playbook can be run to:

1. Identify problematic PersistentVolumes (PVs) and PersistentVolumeClaims (PVCs)
2. Fix permissions on storage directories
3. Delete and recreate problematic storage objects
4. Run test pods to verify storage functionality
5. Generate a comprehensive storage status report

Run the storage playbook with:

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.storage.yml -K
```

Common storage issues you may encounter include:

- **Incorrect directory permissions**: Local storage directories must have the correct permissions for Kubernetes to use them. Our playbook ensures all directories have `0777` permissions.
- **PVs stuck in Released state**: After a PVC is deleted, its PV may get stuck in the Released state. The storage playbook can detect and fix these issues by deleting and recreating problematic PVs.
- **Volume binding failures**: If your PVC fails to bind to a PV, check that the storage class names match exactly and that the requested storage size is available.
- **Node affinity issues**: Local PVs are bound to specific nodes. Ensure your pods are scheduled on the correct nodes or use a topology-aware provisioner.

For our homelab setup, we've created storage classes and persistent volumes for each node:

| Node | Storage Class | Available Volumes |
|------|---------------|-------------------|
| arthur | local-storage-arthur | 3 tiny (5Gi), 2 small (10Gi), 1 medium (20Gi), 1 large (50Gi) |
| ford | local-storage-ford | 3 tiny (5Gi), 2 small (10Gi), 1 medium (20Gi), 1 large (50Gi) |
| trillian | local-storage-trillian | 3 tiny (5Gi), 2 small (10Gi), 1 medium (20Gi), 1 large (50Gi) |
| disasterarea | local-storage-disasterarea | 3 tiny (5Gi), 2 small (10Gi), 1 medium (20Gi), 1 large (50Gi) |

To set up storage initially on all nodes, use:

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.storage.yml -K
```

## Workload Tests

Deploy a simple application to test complete functionality:

```yaml
---
# test-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: test-service
spec:
  type: NodePort
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
```

Apply and test:

```bash
kubectl apply -f test-deployment.yaml

# Check deployment status
kubectl get deployment test-deployment

# Check service and get NodePort
kubectl get service test-service

# Test accessing the service from any node
curl http://<any-node-ip>:<nodeport>
```

The test deployment should show all pods running and the curl command should return the nginx welcome page.

## Scheduled Testing with Playbooks

We've created a comprehensive Ansible playbook for automated testing in our homelab environment. The playbook is located at `playbooks/kubernetes/k8s.test.yml` and performs the following test types:

1. Basic cluster health checks
2. Node status verification
3. Control plane component tests
4. Network connectivity tests (using test pods and services)
5. Storage functionality tests (using PVCs)
6. Complete workload deployment tests

The playbook generates a summary report at `/root/k8s-test-results.txt` on the control plane node, which provides an overview of all test results.

The test manifests are stored in the `manifests/k8s_cluster/test/` directory:
- `test-network.yaml`: Tests pod-to-pod and pod-to-service connectivity
- `test-storage.yaml`: Tests persistent volume claims and storage
- `test-deployment.yaml`: Tests deployment functionality with multiple replicas

Run this playbook regularly as part of your maintenance routine:

```bash
ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.test.yml -K
```

This will execute all tests and provide a detailed report of your cluster's health.

## Troubleshooting Common Issues

When tests fail, use these troubleshooting steps:

1. **Node NotReady status**:
   - Check kubelet logs: `journalctl -u kubelet`
   - Verify Docker/containerd status: `systemctl status containerd`

2. **Network connectivity issues**:
   - Check CNI plugin status: `kubectl get pods -n kube-system | grep flannel`
   - Verify network policies: `kubectl get networkpolicies --all-namespaces`

3. **Failed pod scheduling**:
   - Check scheduler logs: `kubectl logs -n kube-system kube-scheduler-<control-plane-name>`
   - Look for resource constraints: `kubectl describe nodes | grep -A 5 Allocatable`

4. **Storage problems**:
   - Verify PV/PVC binding: `kubectl get pv,pvc`
   - Check storage provisioner logs: `kubectl logs -n kube-system <provisioner-pod>`

## Next Steps

After successfully testing your Kubernetes cluster:

1. Set up monitoring and alerting with Prometheus and Grafana
2. Configure log aggregation with ELK or Loki
3. Implement backup and disaster recovery procedures
4. Deploy your actual workloads with confidence

Remember to run these tests after any significant cluster changes or upgrades to ensure continued proper operation.