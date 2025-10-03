# Step 3: Resolve Storage and Database Issues

## Overview

In this step, you'll fix the persistent storage issues and get the database running properly. The PostgreSQL pod is failing due to storage and configuration problems.

## Current Problems

- PersistentVolumeClaim references non-existent storage class
- Database deployment has wrong image tag
- Missing environment variables for database initialization
- Insufficient memory limits for database operation

## Tasks

### 1. Fix Persistent Volume Claim

The current PVC references a non-existent storage class. Check available storage classes:

```bash
# Check available storage classes
kubectl get storageclass

# Check the current PVC status
kubectl get pvc -n webapp
kubectl describe pvc postgres-pvc -n webapp
```

Fix the PVC by using the correct storage class:

```bash
# Delete the broken PVC first
kubectl delete pvc postgres-pvc -n webapp

# Create new PVC with correct storage class
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard  # Use available storage class
  resources:
    requests:
      storage: 1Gi
EOF
```

### 2. Fix Database Deployment

The PostgreSQL deployment has several issues. Let's fix them:

```bash
kubectl edit deployment postgres -n webapp
```

**Issues to fix:**
1. **Wrong image**: Change `postgres:13-wrong` to `postgres:13`
2. **Missing environment variables**: Add required PostgreSQL env vars
3. **Insufficient memory**: Increase memory limits
4. **Wrong PVC reference**: Update volume claim name

Apply the corrected deployment:

```bash
cat << 'EOF' | kubectl apply -f -
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