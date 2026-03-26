# playbooks/kubernetes/files/

Place the following files here before running the corresponding playbooks:

| File | Source | Used by |
|---|---|---|
| `homelab-ca.pem` | Export from OPNsense: System → Trust → Authorities → Export CA cert | `k8s.containerd-mirror.up.yml` |
