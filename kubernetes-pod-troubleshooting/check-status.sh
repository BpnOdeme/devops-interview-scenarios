#!/bin/bash

# Status Check Script - Quick overview of the current state

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Kubernetes Troubleshooting - Status Check        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check namespaces
echo -e "${YELLOW}📦 Namespaces:${NC}"
if kubectl get namespace webapp &> /dev/null; then
    echo -e "  ${GREEN}✅ webapp namespace exists${NC}"
else
    echo -e "  ${RED}❌ webapp namespace missing${NC}"
fi

if kubectl get namespace ingress-nginx &> /dev/null; then
    echo -e "  ${GREEN}✅ ingress-nginx namespace exists${NC}"
else
    echo -e "  ${RED}❌ ingress-nginx namespace missing (run setup.sh)${NC}"
fi

echo ""
echo -e "${YELLOW}🔍 Pods Status:${NC}"
kubectl get pods -n webapp -o wide

# Count pod states
RUNNING=$(kubectl get pods -n webapp --no-headers 2>/dev/null | grep -c "Running" || echo "0")
TOTAL=$(kubectl get pods -n webapp --no-headers 2>/dev/null | wc -l || echo "0")

echo ""
if [ "$RUNNING" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo -e "${GREEN}✅ All pods running ($RUNNING/$TOTAL)${NC}"
else
    echo -e "${YELLOW}⚠️  Pods running: $RUNNING/$TOTAL${NC}"
fi

echo ""
echo -e "${YELLOW}🔌 Services:${NC}"
kubectl get svc -n webapp

echo ""
echo -e "${YELLOW}📡 Endpoints:${NC}"
kubectl get endpoints -n webapp

echo ""
echo -e "${YELLOW}🌐 Ingress:${NC}"
kubectl get ingress -n webapp

if kubectl get ingress webapp-ingress -n webapp &> /dev/null; then
    echo ""
    echo -e "${YELLOW}📝 Ingress Details:${NC}"
    kubectl describe ingress webapp-ingress -n webapp | grep -A 10 "Rules:"
fi

echo ""
echo -e "${YELLOW}💾 PVCs:${NC}"
kubectl get pvc -n webapp

echo ""
echo -e "${YELLOW}🎛️  Ingress Controller:${NC}"
if kubectl get namespace ingress-nginx &> /dev/null; then
    kubectl get pods -n ingress-nginx
    echo ""
    kubectl get svc -n ingress-nginx ingress-nginx-controller

    INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null)
    if [ -n "$INGRESS_PORT" ]; then
        echo ""
        echo -e "${GREEN}🌍 Ingress NodePort: $INGRESS_PORT${NC}"
        echo -e "${BLUE}   Use this port in Killercoda Traffic Port Accessor${NC}"
    fi
else
    echo -e "${RED}❌ Ingress controller not installed${NC}"
fi

echo ""
echo -e "${YELLOW}🧪 Quick Tests:${NC}"

# Test API pods
API_RUNNING=$(kubectl get pods -n webapp -l app=api --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [ "$API_RUNNING" -eq 2 ]; then
    echo -e "  ${GREEN}✅ API pods: 2/2 running${NC}"
else
    echo -e "  ${YELLOW}⚠️  API pods: $API_RUNNING/2 running${NC}"
fi

# Test ConfigMaps
if kubectl get configmap api-config -n webapp &> /dev/null; then
    echo -e "  ${GREEN}✅ api-config ConfigMap exists${NC}"
else
    echo -e "  ${RED}❌ api-config ConfigMap missing${NC}"
fi

if kubectl get configmap nginx-config -n webapp &> /dev/null; then
    echo -e "  ${GREEN}✅ nginx-config ConfigMap exists${NC}"
else
    echo -e "  ${RED}❌ nginx-config ConfigMap missing${NC}"
fi

# Test PVC
PVC_STATUS=$(kubectl get pvc postgres-pvc -n webapp -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" = "Bound" ]; then
    echo -e "  ${GREEN}✅ postgres-pvc is Bound${NC}"
else
    echo -e "  ${YELLOW}⚠️  postgres-pvc status: ${PVC_STATUS}${NC}"
fi

echo ""
echo -e "${YELLOW}🔗 Test Commands:${NC}"
echo ""

if [ -n "$INGRESS_PORT" ]; then
    echo "Test API health:"
    echo "  curl -H \"Host: webapp.local\" http://localhost:$INGRESS_PORT/api/health"
    echo ""
    echo "Test frontend:"
    echo "  curl -H \"Host: webapp.local\" http://localhost:$INGRESS_PORT/"
fi

echo ""
echo "Test database:"
echo "  kubectl exec -it deployment/postgres -n webapp -- pg_isready -U webapp_user"

echo ""
echo "Test Redis:"
echo "  kubectl exec -it deployment/redis -n webapp -- redis-cli ping"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
