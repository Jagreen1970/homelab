# MetalLB Configuration for Homelab Kubernetes Cluster

MetalLB is a load-balancer implementation for bare metal Kubernetes clusters. It provides a network load-balancer implementation by announcing service IPs via ARP (Layer 2 mode).

## Components

This directory contains the following files:

- `metallb-namespace.yaml`: Creates the metallb-system namespace
- `metallb-config.yaml`: Configuration for IP address pool and L2 advertisement

## IP Address Pool

The configuration uses the IP address range: `10.1.0.0-10.1.255.255`.

This range should be:

1. Available on your local network
2. Not conflicting with existing DHCP ranges
3. Not used by other devices in your network

## Installation Procedure

MetalLB will be installed by the `k8s.metallb.yml` Ansible playbook.

## Usage

After installation, LoadBalancer services will automatically receive external IPs from the configured pool. The ingress-nginx-controller service will be able to use LoadBalancer type and get an external IP.

## Troubleshooting

- Verify MetalLB pods are running: `kubectl get pods -n metallb-system`
- Check address assignments: `kubectl get svc -n ingress-nginx ingress-nginx-controller`
- View MetalLB logs: `kubectl logs -n metallb-system -l app=metallb,component=controller`
- Check speaker logs: `kubectl logs -n metallb-system -l app=metallb,component=speaker`

