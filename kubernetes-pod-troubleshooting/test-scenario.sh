#!/bin/bash

# Kubernetes Pod Troubleshooting Scenario - Automated Test Script
# This script helps you test each step of the scenario automatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Function to wait for user
wait_for_user() {
    echo -e "\n${YELLOW}Press ENTER to continue...${NC}"
    read
}

# Function to check if command succeeded
check_result() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$1 - Failed!"
        return 1
    fi
}

# Step 0: Initial Setup Check
test_step0_setup() {
    print_step "STEP 0: Checking Initial Setup"

    print_info "Checking if setup.sh has been run..."

    # Check if webapp namespace exists
    if kubectl get namespace webapp &> /dev/null; then
        print_success "webapp namespace exists"
    else
        print_error "webapp namespace not found - Run setup.sh first!"
        echo ""
        echo "Run: bash setup.sh"
        exit 1
    fi

    # Check if ingress-nginx exists
    if kubectl get namespace ingress-nginx &> /dev/null; then
        print_success "ingress-nginx namespace exists"
    else
        print_error "ingress-nginx namespace not found - Ingress controller not installed!"
        print_warning "This means setup.sh is outdated. Update it first!"
        exit 1
    fi

    # Show initial pod status
    echo ""
    print_info "Initial pod status in webapp namespace:"
    kubectl get pods -n webapp

    echo ""
    print_info "Expected broken pods:"
    echo "  - frontend: ContainerCreating (missing ConfigMap)"
    echo "  - postgres: Pending/ImagePullBackOff (wrong image/missing PVC)"
    echo "  - api: ContainerCreating (missing ConfigMap)"
    echo "  - redis: Running ✅ (healthy reference)"

    wait_for_user
}

# Step 1: Diagnose Pod Failures
test_step1_diagnose() {
    print_step "STEP 1: Diagnosing Pod Failures"

    print_info "Getting pod status..."
    kubectl get pods -n webapp

    echo ""
    print_info "Describing broken pods..."

    # Describe each broken pod
    for pod in frontend postgres api; do
        echo ""
        print_info "Describing $pod pod:"
        kubectl describe pod -l app=$pod -n webapp | grep -A 10 "Events:" || true
    done

    echo ""
    print_info "Check completed! Look for:"
    echo "  - Missing ConfigMaps"
    echo "  - Image pull errors"
    echo "  - Volume mount failures"
    echo "  - Missing PVCs"

    wait_for_user
}

# Step 2: Fix API and Services
test_step2_api_services() {
    print_step "STEP 2: Fixing API Pods and Services"

    print_info "Current API pod status:"
    kubectl get pods -n webapp -l app=api

    echo ""
    print_info "Applying API ConfigMap fix..."
    if kubectl apply -f /root/k8s-app/configmaps/api-config.yaml; then
        print_success "API ConfigMap created"
    else
        print_error "Failed to create API ConfigMap"
    fi

    sleep 3

    echo ""
    print_info "Fixing API service selector..."
    kubectl patch svc api-service -n webapp -p '{"spec":{"selector":{"app":"api"}}}'
    check_result "API service selector fixed"

    echo ""
    print_info "Creating missing services..."

    # Create frontend-service
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: webapp
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
    check_result "frontend-service created"

    # Create postgres-service
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: webapp
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
    check_result "postgres-service created"

    echo ""
    print_info "Waiting for API pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=api -n webapp --timeout=60s || true

    echo ""
    print_info "Current status:"
    kubectl get pods,svc -n webapp

    echo ""
    print_info "Running Step 2 verification..."
    if [ -f /usr/local/bin/verify-step2 ]; then
        /usr/local/bin/verify-step2
    else
        print_warning "verify-step2 script not found"
    fi

    wait_for_user
}

# Step 3: Fix Storage and Database
test_step3_storage_database() {
    print_step "STEP 3: Fixing Storage and Database"

    print_info "Current postgres pod status:"
    kubectl get pods -n webapp -l app=postgres

    echo ""
    print_info "Checking PVC status..."
    kubectl get pvc -n webapp

    echo ""
    print_info "Checking storage classes..."
    kubectl get storageclass

    echo ""
    print_info "Fixing postgres image..."
    kubectl set image deployment/postgres postgres=postgres:15 -n webapp
    check_result "Postgres image updated"

    echo ""
    print_info "Deleting old PVC with wrong storage class..."
    kubectl delete pvc postgres-pvc -n webapp --force --grace-period=0 || true

    sleep 3

    echo ""
    print_info "Creating new PVC with correct storage class..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: webapp
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
EOF
    check_result "PVC created with local-path storage class"

    echo ""
    print_info "Fixing postgres deployment - updating PVC name and adding env vars..."
    kubectl set env deployment/postgres -n webapp \
        POSTGRES_USER=webapp_user \
        POSTGRES_PASSWORD=webapp_pass \
        POSTGRES_DB=webapp
    check_result "Postgres environment variables set"

    # Fix PVC name in deployment
    kubectl patch deployment postgres -n webapp -p '{"spec":{"template":{"spec":{"volumes":[{"name":"postgres-storage","persistentVolumeClaim":{"claimName":"postgres-pvc"}}]}}}}'
    check_result "Postgres PVC reference fixed"

    echo ""
    print_info "Increasing postgres memory limits..."
    kubectl set resources deployment/postgres -n webapp \
        --limits=memory=256Mi,cpu=500m \
        --requests=memory=128Mi,cpu=250m
    check_result "Postgres resources updated"

    echo ""
    print_info "Waiting for postgres to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n webapp --timeout=120s || true

    echo ""
    print_info "Testing database connection..."
    sleep 5
    kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user || print_warning "DB not ready yet"

    echo ""
    print_info "Current status:"
    kubectl get pods,pvc -n webapp

    wait_for_user
}

# Step 4: Configure Ingress
test_step4_ingress() {
    print_step "STEP 4: Configuring Ingress and External Access"

    print_info "Checking ingress controller status..."
    kubectl get pods -n ingress-nginx
    kubectl get svc -n ingress-nginx

    echo ""
    print_info "Applying frontend ConfigMap..."
    if kubectl apply -f /root/k8s-app/configmaps/nginx-config.yaml; then
        print_success "Frontend ConfigMap created"
    else
        print_error "Failed to create frontend ConfigMap"
    fi

    sleep 3

    echo ""
    print_info "Waiting for frontend pod to be ready..."
    kubectl wait --for=condition=ready pod -l app=frontend -n webapp --timeout=60s || true

    echo ""
    print_info "Fixing ingress configuration..."
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  namespace: webapp
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: webapp.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
EOF
    check_result "Ingress configuration updated"

    echo ""
    print_info "Getting ingress NodePort..."
    INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
    echo "Ingress NodePort: $INGRESS_PORT"

    echo ""
    print_info "Testing ingress access..."
    echo "Testing API health endpoint:"
    curl -s -H "Host: webapp.local" "http://localhost:$INGRESS_PORT/api/health" || print_warning "API not accessible yet"

    echo ""
    echo "Testing frontend:"
    curl -s -H "Host: webapp.local" "http://localhost:$INGRESS_PORT/" | head -5 || print_warning "Frontend not accessible yet"

    echo ""
    print_info "Current status:"
    kubectl get pods,svc,ingress -n webapp

    echo ""
    print_success "Use Killercoda Traffic Port Accessor with port: $INGRESS_PORT"

    wait_for_user
}

# Step 5: Final Verification
test_step5_verification() {
    print_step "STEP 5: Final Verification and Optimization"

    print_info "All pods status:"
    kubectl get pods -n webapp -o wide

    echo ""
    print_info "All services:"
    kubectl get svc -n webapp

    echo ""
    print_info "All endpoints:"
    kubectl get endpoints -n webapp

    echo ""
    print_info "Ingress status:"
    kubectl get ingress -n webapp

    echo ""
    print_info "PVC status:"
    kubectl get pvc -n webapp

    echo ""
    print_info "Testing complete application stack..."

    INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
    echo "Ingress NodePort: $INGRESS_PORT"

    echo ""
    echo "Testing API:"
    curl -s -H "Host: webapp.local" "http://localhost:$INGRESS_PORT/api/health"

    echo ""
    echo "Testing frontend:"
    curl -s -H "Host: webapp.local" "http://localhost:$INGRESS_PORT/" | head -10

    echo ""
    print_info "Testing database connectivity..."
    kubectl exec -it deployment/postgres -n webapp -- psql -U webapp_user -d webapp -c "SELECT version();" || print_warning "DB connection test failed"

    echo ""
    print_info "Testing Redis connectivity..."
    kubectl exec -it deployment/redis -n webapp -- redis-cli ping

    echo ""
    print_info "Checking pod logs..."
    for app in api frontend postgres redis; do
        echo ""
        print_info "$app pod logs (last 5 lines):"
        kubectl logs deployment/$app -n webapp --tail=5 || true
    done

    echo ""
    print_info "Running Step 5 verification..."
    if [ -f /usr/local/bin/verify-step5 ]; then
        /usr/local/bin/verify-step5
    else
        print_warning "verify-step5 script not found"
    fi

    wait_for_user
}

# Main menu
show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Kubernetes Pod Troubleshooting - Automated Test         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Select a step to test:"
    echo ""
    echo "  0) Check Initial Setup"
    echo "  1) Step 1 - Diagnose Pod Failures"
    echo "  2) Step 2 - Fix API and Services"
    echo "  3) Step 3 - Fix Storage and Database"
    echo "  4) Step 4 - Configure Ingress"
    echo "  5) Step 5 - Final Verification"
    echo ""
    echo "  A) Run All Steps Automatically"
    echo "  Q) Quit"
    echo ""
    echo -n "Enter your choice: "
}

# Main loop
main() {
    while true; do
        show_menu
        read -r choice

        case $choice in
            0) test_step0_setup ;;
            1) test_step1_diagnose ;;
            2) test_step2_api_services ;;
            3) test_step3_storage_database ;;
            4) test_step4_ingress ;;
            5) test_step5_verification ;;
            A|a)
                test_step0_setup
                test_step1_diagnose
                test_step2_api_services
                test_step3_storage_database
                test_step4_ingress
                test_step5_verification
                print_success "All steps completed!"
                wait_for_user
                ;;
            Q|q)
                echo ""
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Run main
main
