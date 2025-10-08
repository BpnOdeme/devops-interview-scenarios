# Kubernetes Pod Troubleshooting

## Scenario Overview

You've been called to fix a critical Kubernetes cluster where multiple pods are failing and the application is not accessible. The operations team deployed a web application with the following components:

- **Frontend**: Static web application served by Nginx
- **Backend API**: Mock REST API (nginx) returning JSON responses
- **Database**: PostgreSQL with persistent storage
- **Cache**: Redis for data caching
- **Ingress**: Nginx Ingress Controller for external access

**Note**: The API is a mock service for this troubleshooting exercise - the focus is on Kubernetes infrastructure, not application development.

## The Problem

The operations team reports multiple issues:
- ❌ Pods are in ContainerCreating,Pending states
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
- `curl` - Test HTTP endpoints
- `dig/nslookup` - DNS troubleshooting
- `nano/vim` - Edit configuration files

## Key Kubernetes Objects

All configuration files are in `/root/k8s-app/` directory:

- `deployments/` - Pod deployment configurations (api, frontend, postgres, redis)
- `services/` - Service definitions for internal communication
- `storage/` - PersistentVolumeClaim for database
- `configmaps/` - Configuration for nginx (API and frontend)
- `ingress/` - Ingress rules for external access
- `README.md` - Lab documentation and hints

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

```

## Success Criteria

- ✅ All pods are in Running state (1/1 or 2/2 Ready)
- ✅ Services have valid endpoints
- ✅ API service selector matches pod labels
- ✅ PostgreSQL pod is running with correct image and env vars
- ✅ PersistentVolumeClaim is bound
- ✅ Frontend and API ConfigMaps exist
- ✅ Pod logs show successful startup (no errors)
- ✅ Database connections work (test with pg_isready)
- ✅ Redis is accessible (test with redis-cli ping)

## Cluster Access

The Kubernetes cluster is already running with:
- **Context**: `kubectl config current-context`

Click **START** to begin troubleshooting!