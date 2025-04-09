# PostgreSQL Cluster with pgAdmin for Kubernetes

This directory contains Kubernetes manifests for deploying a PostgreSQL cluster with pgAdmin in Kubernetes.

## Overview

This deployment provides:

- PostgreSQL cluster with primary and replica nodes
- ReadWriteOnce for primary operations directed to the master node
- Read operations can be directed to any node through the postgres-read service
- pgAdmin web interface for database administration
- Persistent storage for both PostgreSQL and pgAdmin

## Prerequisites

- A Kubernetes cluster
- `kubectl` configured to communicate with your cluster
- Longhorn or another storage class installed (manifests are configured to use Longhorn)
- Ingress controller installed in your cluster (for pgAdmin ingress)

## Deployment Instructions

1. Create the namespace:

    ```bash
    kubectl apply -f namespace.yml
    ```

2. Create secrets (first update the secrets with your own values):

    ```bash
    kubectl apply -f postgres-secrets.yml
    ```

3. Deploy the ConfigMap:

    ```bash
    kubectl apply -f postgres-configmap.yml
    ```

4. Deploy PostgreSQL StatefulSet and Services:

    ```bash
    kubectl apply -f postgres-statefulset.yml
    kubectl apply -f postgres-services.yml
    ```

5. Deploy pgAdmin:

    ```bash
    kubectl apply -f pgadmin-pvc.yml
    kubectl apply -f pgadmin-deployment.yml
    kubectl apply -f pgadmin-service.yml
    kubectl apply -f pgadmin-ingress.yml
    ```

## Testing the Deployment

1. Deploy the test client:

    ```bash
    kubectl apply -f test-postgres-client.yml
    ```

2. Run the test script:

    ```bash
    chmod +x test-connection.sh
    ./test-connection.sh
    ```

## PostgreSQL Connection Information

- Primary (read/write):
  - Service: `postgres.postgres.svc.cluster.local`
  - Port: 5432
  - Username: postgres 
  - Password: Check the postgres-secrets.yml file

- Read-only replicas:
  - Service: `postgres-read.postgres.svc.cluster.local`
  - Port: 5432
  - Username: postgres
  - Password: Check the postgres-secrets.yml file

## pgAdmin Access

pgAdmin is available at the hostname configured in the ingress (default: pgadmin.stefan-strich.de).

Login credentials:
- Email: Check the postgres-secrets.yml file
- Password: Check the postgres-secrets.yml file

### Connecting to PostgreSQL from pgAdmin

1. Login to pgAdmin using the credentials above
2. Right-click on "Servers" and select "Create" > "Server..."
3. In the General tab, give your server a name (e.g., "PostgreSQL Cluster")
4. In the Connection tab, enter:
   - Host: postgres
   - Port: 5432
   - Database: postgres
   - Username: postgres
   - Password: Check the postgres-secrets.yml file
5. Click "Save"

## Troubleshooting

- Check pod status: `kubectl get pods -n postgres`
- View PostgreSQL logs: `kubectl logs -n postgres postgres-0`
- View pgAdmin logs: `kubectl logs -n postgres deployment/pgadmin`