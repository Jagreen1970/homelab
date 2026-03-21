# Task 05 — Prometheus + Alerting Stack

## Status: TODO
## Priority: MEDIUM — cluster currently has no metrics or alerting
## Prereqs: task-01 (stable cluster), task-03 (longhorn storage for Prometheus PVC)

## Summary
Deploy kube-prometheus-stack into the existing `monitoring` namespace.
Reuse the existing Grafana instance (disable chart's built-in Grafana).
Add ingress for prometheus.home and alertmanager.home.

## Files to create
- `manifests/k8s_cluster/monitoring/prometheus-stack-values.yaml`
- `playbooks/kubernetes/k8s.prometheus.yml`
- `manifests/k8s_cluster/monitoring/ingress-prometheus.yaml`
- `manifests/k8s_cluster/monitoring/ingress-alertmanager.yaml`
- `manifests/k8s_cluster/monitoring/prometheus-datasource.yaml` — Grafana data source ConfigMap

## Files to modify
- `playbooks/kubernetes/k8s_vars.yml` — add `kube_prometheus_stack_version`
- `playbooks/kubernetes/k8s.all.yml` — import k8s.prometheus.yml after k8s.logging.yml

## Key Helm values summary
- `grafana.enabled: false` — reuse existing Grafana from loki-stack
- `prometheus.prometheusSpec.retention: 30d`
- `prometheus.prometheusSpec.storageSpec`: longhorn-distributed, 20Gi
- `alertmanager.alertmanagerSpec.storage`: nfs-storage, 2Gi
- `defaultRules.create: true` — enables default K8s alert rules
- `kubeEtcd.enabled: true` — etcd health monitoring

## Alert coverage (default rules + custom)
- Node: disk pressure, memory pressure, CPU throttling
- PVC: usage > 80%, pending claims
- etcd: leader election failures, high commit latency
- Longhorn: replica degraded, volume unavailable (via ServiceMonitor)
- Workloads: deployment unavailable, crash-looping pods

## Ingress hostnames
- prometheus.home → prometheus-operated:9090
- alertmanager.home → alertmanager-operated:9093

## Grafana data source
- ConfigMap with label `grafana_datasource=1`, picked up by Grafana sidecar
- Adds Prometheus as a new data source to the existing Grafana instance

## Verification
- `kubectl get pods -n monitoring` — prometheus-* and alertmanager-* pods Running
- http://prometheus.home — Prometheus UI loads, targets page shows cluster components
- http://alertmanager.home — Alertmanager UI loads
- Grafana: Prometheus data source shows Connected
- Fire test alert: apply a broken deployment → confirm Alertmanager receives it

## Potential subtasks
- [ ] Write prometheus-stack-values.yaml
- [ ] Write k8s.prometheus.yml playbook
- [ ] Write ingress manifests (prometheus.home, alertmanager.home)
- [ ] Write prometheus-datasource.yaml ConfigMap for Grafana
- [ ] Update k8s_vars.yml with chart version
- [ ] Update k8s.all.yml to include prometheus step
- [ ] Run playbook and verify all pods healthy
- [ ] Add Longhorn ServiceMonitor for replica/volume alerts
