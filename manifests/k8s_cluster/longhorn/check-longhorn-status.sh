#!/bin/bash
# Script to check Longhorn status in the Kubernetes cluster

set -e

echo "=== Longhorn Status Checker ==="
echo "Checking if Longhorn is installed..."

# Check if namespace exists
if ! kubectl get namespace longhorn-system &>/dev/null; then
  echo "❌ Longhorn namespace not found. Longhorn may not be installed."
  echo "To install Longhorn, run: ansible-playbook -i inventory.yml playbooks/kubernetes/k8s.longhorn.yml"
  exit 1
fi

echo "✅ Longhorn namespace found."

# Check for Longhorn storage class
if ! kubectl get storageclass longhorn-distributed &>/dev/null; then
  echo "❌ Longhorn storage class not found. Installation may be incomplete."
  echo "Check Longhorn installation logs."
else
  echo "✅ Longhorn storage class found."
fi

# Check if Longhorn UI is running
if ! kubectl -n longhorn-system get pods -l app=longhorn-ui | grep -q Running; then
  echo "❌ Longhorn UI not running."
  echo "Check Longhorn pod status:"
  kubectl -n longhorn-system get pods
else
  echo "✅ Longhorn UI running."
fi

# Check Longhorn manager status
if ! kubectl -n longhorn-system get pods -l app=longhorn-manager | grep -q Running; then
  echo "❌ Longhorn manager not running properly."
  echo "Check logs with: kubectl -n longhorn-system logs -l app=longhorn-manager"
else
  echo "✅ Longhorn manager running."
fi

# Check node status in Longhorn
echo ""
echo "=== Longhorn Node Status ==="
kubectl -n longhorn-system get nodes.longhorn.io || echo "Unable to get Longhorn nodes"

# Check volume status in Longhorn
echo ""
echo "=== Longhorn Volume Status ==="
kubectl -n longhorn-system get volumes.longhorn.io || echo "No volumes found"

echo ""
echo "=== Access Longhorn UI ==="
echo "To access Longhorn UI, run: kubectl port-forward -n longhorn-system service/longhorn-frontend 8000:80"
echo "Then open http://localhost:8000 in your browser"

echo ""
echo "=== Test Longhorn Storage ==="
echo "To test Longhorn storage, run:"
echo "kubectl apply -f \$(dirname "$0")/../test/test-longhorn-storage.yaml"
echo "kubectl wait --for=condition=ready pod/longhorn-storage-test --timeout=120s"
echo "kubectl exec -it longhorn-storage-test -- cat /data/longhorn-test.txt"
echo ""
echo "To clean up test resources:"
echo "kubectl delete -f \$(dirname "$0")/../test/test-longhorn-storage.yaml"