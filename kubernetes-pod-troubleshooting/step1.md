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

- **ImagePullBackOff**: Wrong image names or tags
- **CrashLoopBackOff**: Application errors or missing dependencies
- **Pending**: Resource constraints or scheduling issues
- **Init**: Missing configuration files or secrets

## Expected Findings

You should discover several issues:
- Database pod has wrong image tag
- Backend pod is missing environment variables
- Frontend pod references non-existent ConfigMap
- Some pods have insufficient resource limits

## Verification

Once you've identified the main issues with the pods, you can proceed to the next step to fix them.

**Hint**: Pay special attention to:
- Image names and tags in deployments
- Environment variables and their values
- ConfigMap and Secret references
- Resource requests and limits