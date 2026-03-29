# GitLab Runner Helm Deployment

This directory contains the configuration for deploying GitLab Runner using Helm with Kubernetes and Buildah container runtime for image builds.

## Prerequisites

- Kubernetes cluster with Helm 3.x installed
- Longhorn storage class configured
- GitLab instance with runner token

## Installation

### 1. Add GitLab Helm Repository

```bash
helm repo add gitlab https://charts.gitlab.io
helm repo update
```

### 2. Create Namespace

```bash
kubectl create namespace runners
```

### 3. Apply Persistent Volume Claims

```bash
kubectl apply -f pvcs.yml
```

This creates two PVCs using Longhorn storage:
- `builds` (20Gi) - Build artifacts and workspace
- `containers` (50Gi) - Container images and Buildah storage

### 4. Install GitLab Runner

```bash
helm install gitlab-runner gitlab/gitlab-runner \
  --namespace runners \
  --values values.yml
```

### 5. Verify Installation

```bash
kubectl get pods -n runners
kubectl logs -n runners deployment/gitlab-runner
```

## Configuration Overview

The runner is configured with:

- **Build Tool**: Buildah (rootless container builds and image pushes)
- **Executor**: Kubernetes
- **Storage**: Longhorn persistent volumes
- **Namespace**: `runners` for runner deployment, configurable job namespace
- **Cleanup**: Automated cleanup cronjob runs daily at 2 AM
- **Security**: Privileged containers for container builds
- **Concurrency**: Limited to 5 concurrent jobs

## Key Features

- Persistent build artifacts storage
- Container image caching with Buildah
- Automated cleanup of old images and artifacts
- Memory-based temporary cache
- Registry service for container builds

## Updating Configuration

1. Modify `values.yml`
2. Upgrade the deployment:

```bash
helm upgrade gitlab-runner gitlab/gitlab-runner \
  --namespace runners \
  --values values.yml
```

## Uninstallation

```bash
helm uninstall gitlab-runner --namespace runners
kubectl delete -f pvcs.yml
kubectl delete namespace runners
```

## TODO

### Security Improvements
- [ ] Implement rootless Buildah configuration
- [ ] Add network policies for runner isolation
- [ ] Configure resource quotas per namespace
- [ ] Implement secrets management with external secrets operator

### Storage Optimization
- [ ] Configure S3/MinIO for distributed caching
- [ ] Implement tiered storage for build artifacts
- [ ] Add storage monitoring and alerting
- [ ] Optimize Buildah storage driver configuration

### Monitoring & Observability
- [ ] Enable Prometheus metrics collection
- [ ] Configure Grafana dashboards for runner metrics
- [ ] Add log aggregation with Loki/ELK stack
- [ ] Implement alerting for failed builds and resource exhaustion
- [ ] Monitor Buildah build performance and image sizes

### Scalability
- [ ] Configure horizontal pod autoscaler (HPA)
- [ ] Implement job-based autoscaling
- [ ] Add support for multiple runner pools
- [ ] Configure spot instance tolerance

### Configuration Management
- [ ] Migrate to GitOps with ArgoCD
- [ ] Implement configuration validation
- [ ] Add environment-specific value files
- [ ] Create automated backup/restore procedures

### Container Registry Integration
- [ ] Configure private registry authentication for Buildah pushes
- [ ] Implement image vulnerability scanning integration
- [ ] Add image signing and verification with Buildah
- [ ] Optimize registry mirror configuration for Buildah pulls
- [ ] Configure multi-stage build optimization

### Buildah-Specific Optimizations
- [ ] Configure Buildah layer caching strategies
- [ ] Implement parallel multi-arch builds
- [ ] Add Buildah security scanning integration
- [ ] Configure optimal storage drivers for Buildah workloads