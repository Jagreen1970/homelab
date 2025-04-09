#!/bin/bash

# Test script to verify PostgreSQL and pgAdmin are running correctly

echo "Checking PostgreSQL pods..."
kubectl get pods -n postgres -l app=postgres

echo "\nChecking pgAdmin pod..."
kubectl get pods -n postgres -l app=pgadmin

echo "\nChecking PostgreSQL services..."
kubectl get svc -n postgres -l app=postgres

echo "\nChecking pgAdmin service..."
kubectl get svc -n postgres -l app=pgadmin

echo "\nChecking ingress..."
kubectl get ingress -n postgres

echo "\nTesting connection to PostgreSQL primary..."
kubectl exec -n postgres postgres-client -- sh -c "PGPASSWORD=postgres-password psql -h postgres -U postgres -c 'SELECT version();'"

echo "\nTesting connection to PostgreSQL replica..."
kubectl exec -n postgres postgres-client -- sh -c "PGPASSWORD=postgres-password psql -h postgres-read -U postgres -c 'SELECT version();'"

echo "\nVerifying pgAdmin is accessible..."
PGADMIN_URL=$(kubectl get ingress -n postgres pgadmin-ingress -o jsonpath='{.spec.rules[0].host}')
echo "pgAdmin should be accessible at: https://$PGADMIN_URL"
echo "Login with:"
echo "Email:    $(kubectl get secret -n postgres postgres-secrets -o jsonpath='{.data.pgadmin-email}' | base64 --decode)"
echo "Password: $(kubectl get secret -n postgres postgres-secrets -o jsonpath='{.data.pgadmin-password}' | base64 --decode)"

echo "\nServer connection details for pgAdmin:"
echo "Host: postgres"
echo "Port: 5432"
echo "Username: postgres"
echo "Password: postgres-password"
