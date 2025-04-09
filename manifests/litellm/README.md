# LiteLLM Proxy Server for Kubernetes

This directory contains Kubernetes manifests for deploying a LiteLLM proxy server in Kubernetes.

## Overview

LiteLLM is a proxy server that provides a unified API for multiple LLM providers. It accepts requests in OpenAI format and routes them to the appropriate LLM provider.

## Prerequisites

- A Kubernetes cluster
- `kubectl` configured to communicate with your cluster
- API keys for your LLM providers (OpenAI, Azure OpenAI, etc.)

## Deployment Instructions

1. Create the namespace:

    ```bash
    kubectl apply -f namespace.yml
    ```

2. Configure your secrets:
    - Edit `secret.yml` and replace the base64-encoded API keys with your own
    - Generate base64-encoded values: `echo -n "your-api-key" | base64`

    ```bash
    kubectl apply -f secret.yml
    ```

3. Deploy the ConfigMap:

    ```bash
    kubectl apply -f configmap.yml
    ```

4. Deploy the application:

    ```bash
    kubectl apply -f deployment.yml
    ```

5. Deploy the service:

    ```bash
    kubectl apply -f service.yml
    ```

## Usage

LiteLLM proxy is configured to be accessed at `http://litellm-service.litellm.svc.cluster.local/v1` from within the cluster.

OpenWebUI is configured to use this LiteLLM proxy as its API endpoint.

## Configuration

Edit `configmap.yml` to:

- Add or remove model providers
- Change model configurations
- Adjust server settings

## Troubleshooting

- Check pod logs: `kubectl logs -n litellm deployment/litellm`
- Check pod status: `kubectl get pods -n litellm`
- Verify secrets: `kubectl describe secret -n litellm litellm-secrets`