#!/bin/bash

# Deploy PostgreSQL and pgAdmin to Kubernetes

# Create namespace
kubectl apply -f namespace.yml

# Create secrets first
kubectl apply -f postgres-secrets.yml

# Deploy PostgreSQL
kubectl apply -f postgres-configmap.yml
kubectl apply -f postgres-statefulset.yml
kubectl apply -f postgres-services.yml

# Deploy pgAdmin
kubectl apply -f pgadmin-pvc.yml
kubectl apply -f pgadmin-deployment.yml
kubectl apply -f pgadmin-service.yml
kubectl apply -f pgadmin-ingress.yml

# Deploy test client
kubectl apply -f test-postgres-client.yml

echo "Waiting for pods to start..."
sleep 10

# Show status
kubectl get pods -n postgres
