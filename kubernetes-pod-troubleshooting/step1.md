# Step 1: Diagnose Pod Failures

## Overview

In this step, you'll investigate why pods are failing to start and identify the root causes of the issues.

## Current Situation

Several pods in the `webapp` namespace are experiencing problems. Your task is to:

1. **Examine Pod Status**: Check which pods are failing and their current state
2. **Analyze Pod Events**: Look at events to understand what's going wrong
3. **Review Pod Logs**: Check container logs for error messages
4. **Identify Configuration Issues**: Find misconfigurations in deployments

## Tasks

### 1. Check Pod Status

First, let's see the current state of all pods in the webapp namespace:

```bash
kubectl get pods -n webapp
```

You should see pods in various failed states like `CrashLoopBackOff`, `ImagePullBackOff`, or `Pending`.

### 2. Investigate Specific Pod Issues

For each failing pod, get detailed information:

```bash
# Describe a specific pod to see events and configuration
kubectl describe pod <pod-name> -n webapp

# Check recent events in the namespace
kubectl get events -n webapp --sort-by='.lastTimestamp'
```

### 3. Examine Pod Logs

If a pod has started but is crashing, check its logs:

```bash
kubectl logs <pod-name> -n webapp
```

### 4. Common Issues to Look For

Based on the pod descriptions and events, identify these common issues:

- **ContainerCreating**: Missing ConfigMaps, Secrets, or PersistentVolumeClaims
- **Pending**: Missing storage resources, scheduling constraints, or image pull issues
- **ImagePullBackOff**: Wrong image names or tags (check carefully for typos like `postgres:13-wrong`)
- **CrashLoopBackOff**: Application errors or missing dependencies inside containers
- **CreateContainerConfigError**: Referenced ConfigMap or Secret doesn't exist

## Expected Findings

You should discover several issues:
- **Frontend pod**: ContainerCreating state - references non-existent ConfigMap (`nginx-config-missing`)
- **Postgres pod**: Pending state - wrong image tag (`postgres:13-wrong`) and missing PersistentVolumeClaim
- **API pods**: CrashLoopBackOff state - container exits with errors, failing liveness probe (check logs for details)
- **Redis pod**: Running successfully (this is the healthy reference)
- **Resource limits**: Several pods have insufficient memory allocations

## Verification

Once you've identified the main issues with the pods, you can proceed to the next step to fix them.

**Hint**: Pay special attention to:
- Image names and tags in deployments
- Environment variables and their values
- ConfigMap and Secret references
- Resource requests and limits