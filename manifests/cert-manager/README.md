# cert-manager for Homelab TLS

This directory contains configuration for cert-manager, which automatically provisions and manages TLS certificates in your Kubernetes cluster.

## Components

1. **cert-manager** - Core components that manage the lifecycle of certificates
2. **Issuers** - Define how certificates are requested (eg. self-signed, Let's Encrypt)

## Files

- `selfsigned-issuer.yaml` - Creates a cluster-wide issuer that generates self-signed certificates

## Usage

After installation, add the following annotation to your Ingress resources:

```yaml
annotations:
  cert-manager.io/cluster-issuer: "selfsigned-issuer"
```

This will automatically create certificates and store them in the specified TLS secret.

## For Production Environments

For public domains (not `.local`), you can use Let's Encrypt by creating an ACME issuer:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: your-email@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

Then use `cert-manager.io/cluster-issuer: "letsencrypt-prod"` in your Ingress resources.
