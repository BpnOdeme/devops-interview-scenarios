# Kubernetes Pod Troubleshooting

## Scenario Overview

You've been called to fix a critical Kubernetes cluster where multiple pods are failing and the application is not accessible. The development team deployed a web application with the following components:

- **Frontend**: React application served by Nginx
- **Backend API**: Node.js REST API with database connectivity
- **Database**: PostgreSQL with persistent storage
- **Cache**: Redis for session management
- **Ingress**: Nginx Ingress Controller for external access

## The Problem

The operations team reports multiple issues:
- ❌ Pods are in CrashLoopBackOff state
- ❌ Application is not accessible from outside the cluster
- ❌ Database connections are failing
- ❌ Services cannot communicate with each other
- ❌ ConfigMaps and Secrets are misconfigured
- ❌ Resource limits causing pod evictions
- ❌ Ingress controller is not routing traffic properly

## Your Mission

1. **Diagnose Pod Issues**: Identify why pods are failing and fix container problems
2. **Fix Networking**: Ensure services can communicate within the cluster
3. **Resolve Storage Issues**: Fix persistent volume and database connectivity problems
4. **Configure Ingress**: Enable external access to the application
5. **Optimize Resources**: Fix resource constraints and limits
6. **Verify End-to-End**: Ensure the complete application stack is functional

## Available Tools

- `kubectl` - Kubernetes command-line tool
- `docker` - Container management (for debugging)
- `curl` - Test HTTP endpoints
- `dig/nslookup` - DNS troubleshooting
- `nano/vim` - Edit configuration files
- `k9s` - Terminal UI for Kubernetes (if available)

## Key Kubernetes Objects

- `/root/k8s-app/namespace.yaml` - Application namespace
- `/root/k8s-app/frontend/` - Frontend deployment and service
- `/root/k8s-app/backend/` - Backend API deployment and service
- `/root/k8s-app/database/` - PostgreSQL deployment, service, and PVC
- `/root/k8s-app/redis/` - Redis cache deployment and service
- `/root/k8s-app/ingress/` - Ingress controller and rules
- `/root/k8s-app/configmaps/` - Application configuration
- `/root/k8s-app/secrets/` - Database credentials and certificates

## Common Kubernetes Commands

```bash
# Get cluster information
kubectl cluster-info

# List all pods with status
kubectl get pods -A

# Describe a problematic pod
kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# List services and endpoints
kubectl get svc -A
kubectl get endpoints -A

# Check ingress status
kubectl get ingress -A

# View persistent volumes
kubectl get pv,pvc -A

# Check resource usage
kubectl top nodes
kubectl top pods -A
```

## Success Criteria

- All pods are in Running state
- Services can communicate internally
- Database and Redis are accessible
- Frontend is accessible via Ingress
- No resource constraint issues
- Application functions end-to-end
- Logs show no error messages

## Cluster Access

The Kubernetes cluster is already running with:
- **Cluster**: Minikube/Kind cluster
- **Context**: `kubectl config current-context`
- **Dashboard**: `minikube dashboard` (if using Minikube)

Click **START** to begin troubleshooting!