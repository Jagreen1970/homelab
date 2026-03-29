# OpenWebUI for Kubernetes

This directory contains Kubernetes manifests for deploying OpenWebUI in Kubernetes.

## Overview

OpenWebUI is a web interface for interacting with Large Language Models. It provides a ChatGPT-like interface that connects to language models via the OpenAI API format.

## Prerequisites

- A Kubernetes cluster
- `kubectl` configured to communicate with your cluster
- LiteLLM proxy server deployed (see ../litellm directory)
- Ingress controller installed in your cluster (for ingress configuration)

## Deployment Instructions

1. Create the namespace:

    ```bash
    kubectl apply -f namespace.yml
    ```

2. Create the persistent volume claim:

    ```bash
    kubectl apply -f pvc.yml
    ```

3. Deploy the application:

    ```bash
    kubectl apply -f deployment.yml
    ```

4. Deploy the service:

    ```bash
    kubectl apply -f service.yml
    ```

5. Deploy the ingress:

    ```bash
    kubectl apply -f ingress.yml
    ```

## Configuration

OpenWebUI is configured to use the LiteLLM proxy service at `http://litellm-service.litellm.svc.cluster.local/v1`.

### Ingress Configuration

Edit `ingress.yml` to adjust:

- Host name (currently configured as `openwebui.stefan-strich.de`)
- TLS configuration
- Path routing

## Persistent Storage

OpenWebUI stores its data in a persistent volume that is claimed via `pvc.yml`. The default size is 10Gi.

## Troubleshooting

- Check pod logs: `kubectl logs -n open-webui deployment/open-webui`
- Check pod status: `kubectl get pods -n open-webui`
- Verify the service: `kubectl get svc -n open-webui`
- Check ingress configuration: `kubectl get ingress -n open-webui`