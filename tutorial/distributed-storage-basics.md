# Understanding Distributed Storage in Kubernetes with Longhorn

## Introduction to Storage in Kuberetes

Before diving into distributed storage, let's understand the basic storage concepts in Kubernetes.

### The Challenge of Container Storage

Containers are ephemeral by nature. When a container stops or crashes, all data inside it is lost. This presents a challenge: how do we store data that needs to persist beyond the lifecycle of a container?

### Kubernetes Storage Basics

Kubernetes solves this with **Persistent Volumes (PVs)** and **Persistent Volume Claims (PVCs)**:

1. **Persistent Volume (PV)**: A piece of storage in the cluster provisioned by an administrator or dynamically
2. **Persistent Volume Claim (PVC)**: A request for storage by a user
3. **Storage Class**: Defines what type of storage to provision when a PVC is created

The standard workflow:

1. Create a PVC requesting a certain amount of storage
2. Kubernetes finds or creates a matching PV
3. The PV is bound to the PVC
4. Mount the PVC into your Pod's containers

### Storage Types in Kubernetes

Kubernetes supports many storage types:

- **Local storage**: Directly attached to a single node
- **Network storage**: Such as NFS, which can be accessed from multiple nodes
- **Cloud storage**: Like AWS EBS, Google Persistent Disk, Azure Disk
- **Distributed storage**: Where data is replicated across multiple nodes (this is where Longhorn comes in!)

## What is Longhorn?

Imagine you have important files on your computer. If your computer crashes, those files are gone. That's like using local storage in Kubernetes.

**Longhorn is like having automatic backups of those files on multiple computers at once.**

Technically speaking, Longhorn is a lightweight, reliable, and easy-to-use distributed block storage system for Kubernetes. It was created by Rancher Labs (now part of SUSE) and is a CNCF (Cloud Native Computing Foundation) Sandbox project.

## Why Use Longhorn?

### The Problem

In a real-world application, you need:

- **Data that survives pod restarts**
- **Data that survives node failures**
- **The ability to move workloads between nodes**

Local storage only solves the first problem. If a node goes down, all data on that node is inaccessible.

### How Longhorn Helps

Longhorn provides:

1. **High availability**: Data is replicated across multiple nodes, so it survives node failures
2. **Volume snapshots**: Point-in-time backups of your data
3. **Easy management**: Simple UI to manage volumes
4. **Node failure tolerance**: Applications can restart on a different node and still access their data
5. **No external dependencies**: Works entirely within your Kubernetes cluster

## How Longhorn Works

### The Core Concept: Data Replication

Longhorn's magic comes from how it handles data:

1. When you create a volume with Longhorn, it creates multiple **replicas** of that volume across different nodes
2. Each write operation is sent to all replicas
3. Reads can come from any working replica

If a node fails:

1. Longhorn detects the failure
2. Creates a new replica on a healthy node
3. Rebuilds the data from existing replicas
4. Your application continues running without data loss

### Key Components

Longhorn consists of several components:

- **Longhorn Manager**: Orchestrates volume operations
- **Longhorn Engine**: Handles data replication and I/O operations
- **Longhorn UI**: Web interface for management
- **CSI Driver**: Connects Longhorn to Kubernetes storage subsystem

## Deploying Longhorn

### Prerequisites

To run Longhorn, you need:

- A Kubernetes cluster with at least 3 nodes (for proper replication)
- `open-iscsi` installed on all nodes
- At least 5GB of free space on each node

### Installation Steps

Longhorn can be installed in multiple ways:

1. **Using Helm** (a Kubernetes package manager):

   ```bash

helm repo add longhorn <https://charts.longhorn.io>
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace

```

2. **Using YAML manifests**:
   ```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.4.1/deploy/longhorn.yaml
```

3. **Using Ansible** (in our homelab):

   ```bash

ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.longhorn.yml

```

### Verification

To verify Longhorn is working:

1. All Longhorn pods should be running:
   ```bash
kubectl get pods -n longhorn-system
```

2. Create a test volume:

   ```bash

kubectl apply -f test-longhorn-pvc.yaml

```

3. Use the volume in a pod and write data to it

## Using Longhorn in Your Applications

### Creating a Persistent Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 5Gi
```

### Using the PVC in a Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-application
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app-container
        image: nginx:latest
        volumeMounts:
        - name: data-volume
          mountPath: /data
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: my-app-data
```

## Real-world Scenarios

### Scenario 1: Database Storage

Databases need reliable storage. With Longhorn:

1. Create a PVC for your database
2. Deploy your database using this PVC
3. If the node running your database fails, Kubernetes can reschedule it to another node
4. Longhorn ensures the data is still accessible at the new location

### Scenario 2: Shared File Storage

For applications that need to share files:

1. Create a PVC with Longhorn
2. Use a ReadWriteMany access mode if supported by your Longhorn version
3. Multiple pods can access the same files

### Scenario 3: Application Migration

When moving applications between nodes:

1. Your application pod moves to a new node
2. Longhorn attaches the volume to the new node
3. All data remains intact

## Managing Longhorn

### The Longhorn UI

Longhorn provides a web UI for management that can be accessed in two ways:

#### Via Ingress (hostname-based access)

If your cluster has an ingress controller, you can access the UI using a hostname:

```
http://longhorn.lab
```

To use this hostname, add an entry to your hosts file:
```
<CLUSTER_IP> longhorn.lab
```

Replace `<CLUSTER_IP>` with any node IP in your cluster.

#### Via Port Forwarding

You can also use port forwarding for direct access:

```bash
kubectl port-forward -n longhorn-system service/longhorn-frontend 8000:80
```

Then open http://localhost:8000 in your browser.

Through the UI, you can:

- Monitor volume health
- Create and restore snapshots
- See how data is distributed across nodes
- Check for any issues with replicas

### Common Operations

**Snapshots**:

Taking a point-in-time backup of your data:

```bash
kubectl -n longhorn-system create -f snapshot.yaml
```

**Expanding volumes**:

```bash
kubectl edit pvc my-app-data
# Increase the storage request size
```

**Backup and Restore**:

Configure a backup target in Longhorn and use the UI to create backups.

## Troubleshooting

Common issues and solutions:

1. **Volume stuck in "Attaching" state**:
   - Check if `iscsid` service is running on all nodes
   - Verify network connectivity between nodes

2. **Replica fails to rebuild**:
   - Check disk space on nodes
   - Look at Longhorn manager logs

3. **Performance issues**:
   - Adjust Longhorn settings for your workload
   - Consider using faster disks for Longhorn storage

## Hands-on Exercises

Let's put your knowledge into practice with these exercises. Each exercise builds on the previous one to help you understand Longhorn step by step.

### Exercise 1: Exploring Longhorn Components

**Objective**: Familiarize yourself with Longhorn's components in your cluster.

**Steps**:

1. Connect to your Kubernetes cluster
2. List all Longhorn pods and understand their roles:

   ```bash

kubectl get pods -n longhorn-system

```
3. Examine the different types of components (managers, engines, UI, CSI plugins)
4. View the Longhorn services:
   ```bash
kubectl get services -n longhorn-system
```

5. Access the Longhorn UI via one of these methods:

   a. Using Ingress (recommended):
   ```
   http://longhorn.lab
   ```
   (Make sure to add this hostname to your hosts file)
   
   b. Using port-forwarding:
   ```bash
kubectl port-forward -n longhorn-system service/longhorn-frontend 8000:80
```
   Then open http://localhost:8000 in your browser

**Questions**:
- How many replicas of the UI pods are running?
- What is the difference between manager and engine components?
- Which Longhorn component interfaces with Kubernetes to provide storage?

### Exercise 2: Creating Your First Longhorn Volume

**Objective**: Create and use a simple persistent volume with Longhorn.

**Steps**:
1. Create a file named `exercise-pvc.yaml` with the following content:
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: exercise-pvc
   spec:
     accessModes:
       - ReadWriteOnce
     storageClassName: longhorn-distributed
     resources:
       requests:
         storage: 1Gi
   ```

2. Apply the configuration:

   ```bash
   kubectl apply -f exercise-pvc.yaml
   ```

3. Verify the PVC was created and bound:

   ```bash
   kubectl get pvc
   ```

4. Create a file named `exercise-pod.yaml`:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: volume-test
   spec:
     containers:
     - name: volume-container
       image: busybox
       command: ["sh", "-c", "echo 'Hello from Longhorn!' > /data/hello.txt && tail -f /dev/null"]
       volumeMounts:
       - name: volume-storage
         mountPath: /data
     volumes:
     - name: volume-storage
       persistentVolumeClaim:
         claimName: exercise-pvc
   ```

5. Apply the pod configuration:

   ```bash
   kubectl apply -f exercise-pod.yaml
   ```

6. Verify the pod is running:

   ```bash
   kubectl get pods
   ```

7. Check that data is being written:

   ```bash
   kubectl exec volume-test -- cat /data/hello.txt
   ```

**Questions**:

- What happens in the Longhorn UI when you create the PVC?
- Which node is the pod scheduled on?
- Where are the replicas of your volume located?

### Exercise 3: Testing Resilience

**Objective**: Experience Longhorn's resilience by simulating failures.

**Steps**:

1. First, identify where your volume is attached by checking the Longhorn UI or using:

   ```bash
   kubectl get pod volume-test -o wide
   ```

   Note which node is running your pod.

2. Write additional data to make sure we have something to verify:

   ```bash
   kubectl exec volume-test -- sh -c "echo 'More data for testing resilience' >> /data/hello.txt"
   ```

3. Delete the pod:

   ```bash
   kubectl delete pod volume-test
   ```

4. Create a new pod that uses the same PVC:

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: recovery-test
   spec:
     containers:
     - name: recovery-container
       image: busybox
       command: ["sh", "-c", "tail -f /dev/null"]
       volumeMounts:
       - name: volume-storage
         mountPath: /data
     volumes:
     - name: volume-storage
       persistentVolumeClaim:
         claimName: exercise-pvc
   ```

   Save this as `recovery-pod.yaml` and apply it:

   ```bash
   kubectl apply -f recovery-pod.yaml
   ```

5. Once the pod is running, check if the data is still there:

   ```bash
   kubectl exec recovery-test -- cat /data/hello.txt
   ```

**Questions**:

- Was the data successfully preserved?
- Did the new pod get scheduled on the same node as the original?
- What happens in the Longhorn UI during this process?

### Exercise 4: Exploring Volume Snapshots

**Objective**: Learn how to create and use Longhorn volume snapshots.

**Steps**:

1. First, add more data to your volume:

   ```bash
   kubectl exec recovery-test -- sh -c "echo 'Data before snapshot - $(date)' >> /data/hello.txt"
   ```

2. In the Longhorn UI, find your volume and create a snapshot:
   - Navigate to the Volume page
   - Click on the volume name (associated with exercise-pvc)
   - Click "Take Snapshot" button
   - Give it a name like "exercise-snapshot-1"

3. Add new data after the snapshot:

   ```bash
   kubectl exec recovery-test -- sh -c "echo 'Data after snapshot - $(date)' >> /data/hello.txt"
   ```

4. View the current content of the file:

   ```bash
   kubectl exec recovery-test -- cat /data/hello.txt
   ```

5. In the Longhorn UI, restore the volume to the snapshot:
   - Go to your volume detail page
   - Find the snapshot you created
   - Click "Revert" on that snapshot
   - Confirm the reversion

6. Check the content of the file again:

   ```bash
   kubectl exec recovery-test -- cat /data/hello.txt
   ```

**Questions**:

- What happened to the data written after the snapshot?
- How long did the reversion process take?
- What are some practical uses for snapshots in a production environment?

### Exercise 5: Volume Expansion

**Objective**: Expand a Longhorn volume to accommodate growing data needs.

**Steps**:

1. Check the current size of your volume:

   ```bash
   kubectl get pvc exercise-pvc
   ```

2. Edit the PVC to increase its size:

   ```bash
   kubectl edit pvc exercise-pvc
   ```

Find the `spec.resources.requests.storage` field and change it from `1Gi` to `2Gi`

3. Verify the change:

   ```bash
   kubectl get pvc exercise-pvc
   ```

4. Inside your pod, check if the filesystem reflects the new size:

   ```bash
   kubectl exec recovery-test -- df -h /data
   ```

**Questions**:

- How does Longhorn handle volume expansion?
- Did you need to restart the pod to recognize the new size?
- What limitations might you encounter when expanding volumes?

### Cleanup

When you've completed the exercises, clean up your resources:

```bash
kubectl delete pod recovery-test
kubectl delete pvc exercise-pvc
```

Check the Longhorn UI to see what happens to the volume and its replicas when you delete the PVC.

## Conclusion

Distributed storage with Longhorn provides reliable, highly available storage for your Kubernetes applications without requiring external infrastructure. It's particularly valuable in environments where hardware failures are possible and data integrity is critical.

By replicating data across multiple nodes, Longhorn ensures that your applications can continue running even if individual nodes fail, making it an excellent solution for applications that need persistent storage in Kubernetes.

Through these exercises, you've gained hands-on experience with creating, using, and managing Longhorn volumes, experiencing firsthand the resilience and flexibility that distributed storage provides.

Remember that Longhorn isn't the only distributed storage solution for Kubernetes. Others include Rook-Ceph, OpenEBS, and Portworx, each with its own strengths and tradeoffs. Choose the one that best fits your specific requirements and constraints.

