# Logging Stack Implementation

This tutorial covers the implementation of a centralized logging stack using Loki and Grafana in our Kubernetes cluster.

## Overview

The logging stack consists of the following components:
- **Loki**: A horizontally scalable, highly available, multi-tenant log aggregation system
- **Promtail**: An agent that ships logs to Loki
- **Grafana**: A visualization platform for logs and metrics

## Architecture

```
[Kubernetes Pods] → [Promtail] → [Loki] → [Grafana]
```

- **Promtail** runs as a DaemonSet on each node, collecting logs from all pods
- **Loki** stores and indexes the logs
- **Grafana** provides visualization and querying capabilities

## Implementation

### 1. Deployment

The logging stack is deployed using Helm:

```bash
ansible-playbook playbooks/kubernetes/k8s.logging.yml
```

This will:
- Create a dedicated `monitoring` namespace
- Deploy Loki, Promtail, and Grafana
- Configure persistent storage using Longhorn
- Set up log retention policies (28 days by default)

### 2. Access

Grafana is accessible at:
```
http://<node-ip>:30000
```

Default credentials:
- Username: `admin`
- Password: `admin` (can be changed via `GRAFANA_ADMIN_PASSWORD` environment variable)

### 3. Pre-configured Dashboards

Three default dashboards are provided:

1. **Kubernetes Pod Logs Overview**
   - System Errors
   - System Warnings
   - Pod Events

2. **System Logs Overview**
   - System Errors
   - System Warnings
   - System Events

3. **Application Logs Overview**
   - Application Errors
   - Application Warnings
   - Application Info

## Usage

### Viewing Logs

1. Access Grafana at `http://<node-ip>:30000`
2. Navigate to "Explore" in the left sidebar
3. Select "Loki" as the data source
4. Use the query builder or LogQL to search logs

### LogQL Examples

Basic queries:
```
# All logs from a specific namespace
{namespace="monitoring"}

# Error logs from all namespaces
{namespace=~".+"} |~ "error|Error|ERROR"

# Logs containing specific text
{namespace=~".+"} |~ "pod|Pod|POD"
```

### Dashboard Customization

1. Navigate to "Dashboards" in the left sidebar
2. Select a dashboard
3. Click the gear icon to edit
4. Modify panels or add new ones as needed

## Maintenance

### Storage Management

- Loki data is stored in Longhorn volumes
- Default retention period: 28 days
- Storage size: 10GB for Loki, 5GB for Grafana

### Updating

To update the logging stack:
```bash
ansible-playbook playbooks/kubernetes/k8s.logging.yml
```

### Troubleshooting

Common issues and solutions:

1. **Cannot access Grafana**
   - Ensure you're using `http://` not `https://`
   - Check if the service is running: `kubectl get pods -n monitoring`
   - Verify port 30000 is accessible

2. **No logs appearing**
   - Check Promtail pods: `kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail`
   - Verify Loki is running: `kubectl get pods -n monitoring -l app.kubernetes.io/name=loki`
   - Check Promtail logs: `kubectl logs -n monitoring -l app.kubernetes.io/name=promtail`

3. **Storage issues**
   - Check Longhorn volumes: `kubectl get pvc -n monitoring`
   - Verify storage class: `kubectl get sc`

## Best Practices

1. **Log Levels**
   - Use appropriate log levels (ERROR, WARNING, INFO)
   - Include relevant context in log messages
   - Avoid logging sensitive information

2. **Retention**
   - Adjust retention period based on storage capacity
   - Consider implementing log rotation
   - Archive important logs before deletion

3. **Performance**
   - Monitor Loki's performance
   - Adjust query time ranges as needed
   - Use appropriate log sampling if volume is high

## Next Steps

1. Set up log alerts for critical errors
2. Configure log aggregation for specific applications
3. Implement log backup procedures
4. Add custom dashboards for specific use cases 