# Task 06 — K8s integration (containerd mirror + CA trust)

## Status: TODO
## Priority: MEDIUM
## Prereqs: task-05

## Summary
Configure all K8s nodes to trust the Homelab CA (so TLS connections to Nexus succeed)
and configure containerd to use `docker-proxy.home` as a pull-through mirror for
Docker Hub. Also create an imagePullSecret manifest for pulling from `homelab-docker`.

---

## Files to create
- `playbooks/kubernetes/k8s.containerd-mirror.up.yml`
- `playbooks/kubernetes/k8s.containerd-mirror.down.yml`
- `manifests/nexus/imagepull-secret.yaml`

---

## Playbook: k8s.containerd-mirror.up.yml

Targets: `k8s_control_plane` + `k8s_workers`

Tasks in order:
1. Copy `homelab-ca.pem` (exported in task-05) to
   `/usr/local/share/ca-certificates/homelab-ca.crt` on each node
2. Run `update-ca-certificates` to add it to the OS trust store
3. Add the mirror block to `/etc/containerd/config.toml`:
   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
     endpoint = ["https://docker-proxy.home"]
   ```
4. Restart containerd: `systemctl restart containerd`
5. Assert containerd is active: `systemctl is-active containerd`

See `playbooks/kubernetes/k8s.containerd-mirror.up.yml` for the implementation.

---

## Playbook: k8s.containerd-mirror.down.yml

Reverses all changes:
1. Remove `/usr/local/share/ca-certificates/homelab-ca.crt`
2. Run `update-ca-certificates`
3. Remove the mirror block from `/etc/containerd/config.toml`
4. Restart containerd

---

## imagePullSecret manifest

`manifests/nexus/imagepull-secret.yaml` — apply per namespace that pulls local images.

Generate the `.dockerconfigjson` value:
```bash
kubectl create secret docker-registry nexus-pull \
  --docker-server=docker.home \
  --docker-username=admin \
  --docker-password=<nexus-admin-password> \
  --dry-run=client -o yaml > manifests/nexus/imagepull-secret.yaml
```

Apply to required namespaces:
```bash
kubectl apply -f manifests/nexus/imagepull-secret.yaml -n <namespace>
```

Or patch the default ServiceAccount to auto-attach in a namespace:
```bash
kubectl patch serviceaccount default -n <namespace> \
  -p '{"imagePullSecrets": [{"name": "nexus-pull"}]}'
```

---

## Run the playbook

```bash
# Place homelab-ca.pem in playbooks/kubernetes/ first (or adjust path in playbook)
ansible-playbook -i inventory.yml \
  playbooks/kubernetes/k8s.containerd-mirror.up.yml -K
```

---

## Verify

```bash
# On any K8s node — confirm CA is trusted
openssl s_client -connect docker-proxy.home:443 -CAfile /etc/ssl/certs/ca-certificates.crt

# From a workstation — deploy a test pod pulling from Nexus Docker Hub proxy
kubectl run test-pull \
  --image=docker-proxy.home/library/alpine:latest \
  --restart=Never

kubectl describe pod test-pull | grep -E 'Image|Pulling|Pulled'
# Should show "Pulling image docker-proxy.home/..." and "Successfully pulled"

# Clean up
kubectl delete pod test-pull
```

## Acceptance criteria
- [ ] `homelab-ca.crt` present on all nodes (`/usr/local/share/ca-certificates/`)
- [ ] `update-ca-certificates` ran successfully on all nodes
- [ ] Containerd config updated on all nodes
- [ ] Containerd restarted and active on all nodes
- [ ] Test pod pulls successfully from `docker-proxy.home/library/alpine:latest`
- [ ] `manifests/nexus/imagepull-secret.yaml` created
