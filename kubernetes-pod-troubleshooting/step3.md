# Step 3: Resolve Storage and Database Issues

## Overview

In this step, you'll fix the persistent storage issues and get the database running properly. The PostgreSQL pod is failing due to storage and configuration problems.

## Current Problems

Based on the setup, the PostgreSQL pod is in **Pending** state due to:
- Database deployment has wrong image tag (`postgres:13-wrong` instead of `postgres:13`)
- Missing PersistentVolumeClaim (no PVC defined in manifests)
- Missing critical environment variables (POSTGRES_USER, POSTGRES_PASSWORD)
- Insufficient memory limits for database operation (64Mi is too low)

## Tasks

### 1. Create Persistent Volume Claim

The PostgreSQL deployment needs persistent storage, but no PVC exists. Let's create one:

```bash
# Check available storage classes
kubectl get storageclass

# Check current PVC status (should be empty)
kubectl get pvc -n webapp
```

Create a new PVC for PostgreSQL:

```bash
# Create PVC with available storage class
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard  # Use 'standard' or available storage class from kubectl get sc
  resources:
    requests:
      storage: 1Gi
EOF

# Verify PVC is created and bound
kubectl get pvc -n webapp
```

### 2. Fix Database Deployment

The PostgreSQL deployment has several critical issues. Let's fix them all:

```bash
# First, check the current deployment
kubectl get deployment postgres -n webapp -o yaml
```

**Issues identified:**
1. **Wrong image**: `postgres:13-wrong` should be `postgres:13`
2. **Missing environment variables**: No POSTGRES_USER and POSTGRES_PASSWORD
3. **Insufficient memory**: 64Mi is too low for PostgreSQL
4. **Missing volume**: No PVC is mounted

Apply the corrected deployment:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13  # Fixed image tag
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: webapp
        - name: POSTGRES_USER
          value: webapp_user
        - name: POSTGRES_PASSWORD
          value: webapp_password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        resources:
          requests:
            memory: "256Mi"  # Increased memory
            cpu: "250m"
          limits:
            memory: "512Mi"  # Increased memory
            cpu: "500m"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc  # Correct PVC name
EOF
```

### 3. Create Database Secret (Better Practice)

Instead of hardcoding passwords, create a secret:

```bash
# Create database credentials secret
kubectl create secret generic postgres-secret \
  --from-literal=username=webapp_user \
  --from-literal=password=webapp_password \
  --from-literal=database=webapp \
  -n webapp

# Update deployment to use secret (optional improvement)
```

### 4. Verify Database Functionality

Once the pod is running, test database connectivity:

```bash
# Check if postgres pod is running
kubectl get pods -n webapp -l app=postgres

# Test database connection
kubectl exec -it deployment/postgres -n webapp -- psql -U webapp_user -d webapp -c "SELECT version();"

# Check if database accepts connections
kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user -d webapp
```

### 5. Update Backend Configuration

Now update the backend deployment to use correct database credentials:

```bash
kubectl edit deployment api -n webapp
```

Update the DATABASE_URL environment variable:
```
DATABASE_URL: "postgresql://webapp_user:webapp_password@postgres-service:5432/webapp"
```

## Expected Results

After completing this step:
- PVC should be bound to available storage
- PostgreSQL pod should be running and healthy
- Database should accept connections
- Backend pod should be able to connect to database

## Verification Commands

```bash
# Check PVC status
kubectl get pvc -n webapp

# Check postgres pod logs
kubectl logs deployment/postgres -n webapp

# Test database connectivity
kubectl exec -it deployment/postgres -n webapp -- pg_isready

# Verify backend can connect to database
kubectl logs deployment/api -n webapp
```

**Next**: Configure ingress and external access to complete the application setup.