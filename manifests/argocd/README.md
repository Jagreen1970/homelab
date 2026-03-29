# ArgoCD UI Access Setup Guide

This guide provides the steps necessary to access the ArgoCD UI through an Ingress resource in your homelab Kubernetes cluster.

## 1. ArgoCD Deployment Overview

ArgoCD is deployed in the `argocd` namespace using the official installation manifest from the ArgoCD project. The deployment includes the following key components:

- **argocd-server**: The main server that hosts the UI and API
- **argocd-repo-server**: Manages repository access
- **argocd-application-controller**: Manages application states
- **argocd-dex-server**: Handles authentication
- **argocd-redis**: Cache and session store

## 2. Ingress Configuration

The ArgoCD UI is exposed via an NGINX Ingress resource defined in `ingress.yaml`. The key configurations include:

- Host: `argocd.local`
- Backend protocol: HTTP
- SSL redirection: Enabled
- TLS configuration: Uses a secret named `argocd-ingress-http`

## 3. SSL/TLS Setup

For secure access, you'll need to ensure one of the following:

- **Option 1**: Use cert-manager to generate a certificate for `argocd.local`
- **Option 2**: Create a self-signed certificate and store it in the `argocd-ingress-http` secret
- **Option 3**: Temporarily disable SSL redirect for testing purposes

## 4. DNS Configuration

Since you're using `.local` domains in your homelab:

1. Add the ArgoCD server IP to your local DNS records or hosts file:
   ```
   YOUR_INGRESS_IP  argocd.local
   ```
2. The ingress controller's external IP is provided by MetalLB, configured in the range `10.1.1.10-10.1.1.250`

## 5. ArgoCD UI Access Checklist

Before accessing the UI, verify:

- [ ] The ArgoCD namespace exists: `kubectl get namespace argocd`
- [ ] ArgoCD pods are running: `kubectl get pods -n argocd`
- [ ] The argocd-server service is exposed: `kubectl get svc -n argocd argocd-server`
- [ ] The ingress resource is properly configured: `kubectl get ingress -n argocd`
- [ ] NGINX Ingress controller is running and has an external IP: `kubectl get svc -n ingress-nginx`
- [ ] DNS/hosts file is configured to resolve `argocd.local` to your ingress IP
- [ ] If using TLS, the secret `argocd-ingress-http` exists: `kubectl get secret -n argocd argocd-ingress-http`

## 6. Default Login Credentials

The default username is `admin`. For the password, retrieve it with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 7. Troubleshooting

If you encounter issues accessing the UI:

1. Verify the ingress controller logs:
   ```bash
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   ```

2. Check ArgoCD server logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
   ```

3. Test connectivity to the ArgoCD server from within the cluster:
   ```bash
   kubectl run -it --rm debug --image=busybox -- wget -qO- argocd-server.argocd.svc.cluster.local:80
   ```

4. If using TLS, ensure your browser trusts the certificate or try accessing with `--insecure` flag

## 8. Next Steps

After successful setup:

1. Change the default admin password
2. Connect your Git repositories to start managing applications
3. Configure SSO if needed for enhanced security
4. Consider setting up the ArgoCD CLI for terminal-based management