# Kubernetes Pod Troubleshooting - Testing Guide

This guide explains how to use the automated testing scripts for the Kubernetes Pod Troubleshooting scenario.

## 🎯 Available Scripts

### 1. **test-scenario.sh** - Interactive Step-by-Step Testing
**Purpose:** Test each step individually or run all steps automatically.

**Features:**
- Interactive menu for selecting steps
- Colored output for better readability
- Automatic execution of fixes
- Wait for user confirmation between steps
- Run all steps automatically

**Usage:**
```bash
cd /root
bash test-scenario.sh
```

**Menu Options:**
- `0` - Check Initial Setup (verify setup.sh ran correctly)
- `1` - Step 1: Diagnose Pod Failures
- `2` - Step 2: Fix API and Services
- `3` - Step 3: Fix Storage and Database
- `4` - Step 4: Configure Ingress
- `5` - Step 5: Final Verification
- `A` - Run All Steps Automatically (full automation)
- `Q` - Quit

### 2. **quick-fix.sh** - One-Command Fix All
**Purpose:** Apply all fixes in one go for rapid testing.

**Features:**
- No interaction needed
- Fixes all steps automatically
- Shows final status
- Perfect for debugging after setup.sh changes

**Usage:**
```bash
cd /root
bash quick-fix.sh
```

**What it does:**
1. Creates API and frontend ConfigMaps
2. Fixes service selectors
3. Creates missing services
4. Updates postgres image and PVC
5. Adds database credentials
6. Configures ingress
7. Waits for all pods to be ready
8. Shows final status

### 3. **check-status.sh** - Current State Overview
**Purpose:** Quick overview of the current cluster state.

**Features:**
- Shows all pods, services, ingress status
- Color-coded output (✅ good, ⚠️ warning, ❌ error)
- Displays ingress NodePort
- Provides test commands
- No modifications made

**Usage:**
```bash
cd /root
bash check-status.sh
```

**Shows:**
- Namespace status
- Pod status (running count)
- Services and endpoints
- Ingress configuration
- PVC status
- Ingress controller status
- ConfigMap existence
- Quick test results

## 🚀 Typical Workflow

### First Time Setup
```bash
# 1. Run setup
bash setup.sh

# 2. Check initial status
bash check-status.sh

# 3. Test step by step (for learning)
bash test-scenario.sh
# Select option 'A' to run all automatically
```

### After Making Changes to setup.sh
```bash
# 1. Delete old namespace
kubectl delete namespace webapp --force --grace-period=0

# 2. Run new setup
bash setup.sh

# 3. Quick fix to verify everything works
bash quick-fix.sh

# 4. Check final status
bash check-status.sh
```

### For Manual Testing
```bash
# 1. Run setup
bash setup.sh

# 2. Use interactive tester
bash test-scenario.sh

# Select individual steps to test:
# - Press '0' to verify setup
# - Press '2' to test Step 2 fixes
# - Press '3' to test Step 3 fixes
# etc.
```

## 📋 Verification Checklist

After running any script, verify:

### ✅ All Pods Running
```bash
kubectl get pods -n webapp
# Should show:
# api-xxx         1/1     Running
# frontend-xxx    1/1     Running
# postgres-xxx    1/1     Running
# redis-xxx       1/1     Running
```

### ✅ Services Have Endpoints
```bash
kubectl get endpoints -n webapp
# All services should have IP addresses
```

### ✅ Ingress Working
```bash
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
curl -H "Host: webapp.local" http://localhost:$INGRESS_PORT/api/health
# Should return: {"status":"healthy"}
```

### ✅ Database Connected
```bash
kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user
# Should return: accepting connections
```

## 🐛 Debugging Tips

### Ingress Not Working
```bash
# Check if controller exists
kubectl get pods -n ingress-nginx

# If missing, setup.sh needs updating
# Check lines 23-34 in setup.sh
```

### Pods Stuck in ContainerCreating
```bash
# Check events
kubectl describe pod <pod-name> -n webapp | grep -A 10 Events

# Common causes:
# - Missing ConfigMap (apply from /root/k8s-app/configmaps/)
# - Missing PVC (check storage class)
```

### PVC Not Binding
```bash
# Check storage class
kubectl get storageclass

# Should use 'local-path' in Killercoda
# Update PVC yaml if needed
```

### Service No Endpoints
```bash
# Check selector matches pod labels
kubectl get svc <service-name> -n webapp -o yaml | grep selector
kubectl get pods -n webapp --show-labels

# Fix with:
kubectl patch svc <service-name> -n webapp -p '{"spec":{"selector":{"app":"<correct-app-label>"}}}'
```

## 🎓 Learning vs Testing Mode

### For Students (Learning Mode)
- Use `test-scenario.sh` with individual step selection
- Read the output carefully
- Understand each fix before applying
- Wait between steps to observe changes

### For Instructors (Testing Mode)
- Use `quick-fix.sh` to verify scenario works
- Use `check-status.sh` for quick health check
- Run after every setup.sh modification

## 📝 Script Maintenance

### Adding New Checks
Edit `check-status.sh` to add new verification items.

### Modifying Fixes
Edit `test-scenario.sh` or `quick-fix.sh` to update fix commands.

### Updating for New Kubernetes Versions
- Check ingress-nginx version in setup.sh
- Update apiVersion in YAML manifests if needed
- Test all scripts after changes

## 🔗 Related Files

- `setup.sh` - Initial broken cluster setup
- `step1.md` - Step 1 instructions
- `step2.md` - Step 2 instructions
- `step3.md` - Step 3 instructions
- `step4.md` - Step 4 instructions
- `step5.md` - Step 5 instructions
- `verify-step2` - Step 2 verification (in /usr/local/bin/)
- `verify-step5` - Step 5 verification (in /usr/local/bin/)

## 💡 Pro Tips

1. **Always check status first**: Run `check-status.sh` before starting
2. **Use color coding**: Green = good, Yellow = warning, Red = error
3. **Read the events**: `kubectl get events -n webapp --sort-by=.lastTimestamp`
4. **Check logs**: `kubectl logs deployment/<name> -n webapp`
5. **Use describe**: `kubectl describe pod/<name> -n webapp`

## 🆘 Common Issues

### Script Permission Denied
```bash
chmod +x test-scenario.sh quick-fix.sh check-status.sh
```

### Kubectl Command Not Found
```bash
# Scripts assume kubectl is in PATH
# Usually not an issue in Killercoda
which kubectl
```

### Namespace Already Exists
```bash
# Clean up before re-running setup
kubectl delete namespace webapp --force --grace-period=0
kubectl delete namespace ingress-nginx --force --grace-period=0
```

## 📊 Expected Timings

- **setup.sh**: ~2-3 minutes (with ingress controller installation)
- **test-scenario.sh** (all steps): ~5-7 minutes
- **quick-fix.sh**: ~2-3 minutes
- **check-status.sh**: ~5-10 seconds

---

**Happy Testing! 🎉**

For questions or issues, check CLAUDE.md for recent changes and troubleshooting history.
