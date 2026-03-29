#!/bin/bash

# Wait for test pod to be ready
echo "Waiting for logging-test pod to be ready..."
kubectl wait --for=condition=ready pod -l app=logging-test -n monitoring --timeout=60s

# Get the pod name
POD_NAME=$(kubectl get pod -l app=logging-test -n monitoring -o jsonpath='{.items[0].metadata.name}')

# Wait for some logs to be generated
echo "Waiting for logs to be generated..."
sleep 10

# Check if logs are being collected by Promtail
echo "Checking if logs are being collected..."
PROMTAIL_LOGS=$(kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=100)
if echo "$PROMTAIL_LOGS" | grep -q "logging-test"; then
    echo "SUCCESS: Logs are being collected by Promtail"
else
    echo "ERROR: No logs found from Promtail"
    exit 1
fi

# Check if logs are being stored in Loki
echo "Checking if logs are being stored in Loki..."
LOKI_POD=$(kubectl get pod -n monitoring -l app=loki -o jsonpath="{.items[0].metadata.name}")
LOKI_LOGS=$(kubectl exec -n monitoring -it $LOKI_POD -- wget -qO- 'http://localhost:3100/loki/api/v1/query?query={container="logging-test"}')
if echo "$LOKI_LOGS" | grep -q "logging-test"; then
    echo "SUCCESS: Logs are stored in Loki"
else
    echo "ERROR: No logs found in Loki"
    exit 1
fi

# Check if Grafana can query the logs
echo "Checking if Grafana can query the logs..."
GRAFANA_POD=$(kubectl get pod -n monitoring -l app.kubernetes.io/instance=logging-stack,app.kubernetes.io/name=grafana -o jsonpath="{.items[0].metadata.name}")
GRAFANA_LOGS=$(kubectl exec -n monitoring -it $GRAFANA_POD -c grafana -- wget -qO- --header='Authorization: Basic YWRtaW46YWRtaW4=' 'http://localhost:3000/api/datasources/proxy/1/loki/api/v1/query?query={container="logging-test"}')
if echo "$GRAFANA_LOGS" | grep -q "logging-test"; then
    echo "SUCCESS: Grafana can query logs"
else
    echo "ERROR: No logs found in Grafana"
    exit 1
fi

echo "All tests passed successfully!" 