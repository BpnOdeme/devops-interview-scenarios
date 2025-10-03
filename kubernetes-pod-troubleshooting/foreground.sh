#!/bin/bash

# Foreground setup for Kubernetes troubleshooting scenario

echo "🚀 Welcome to Kubernetes Pod Troubleshooting!"
echo ""
echo "The cluster is starting up... This may take a few minutes."
echo ""
echo "While you wait, here are some useful commands you'll need:"
echo ""
echo "Basic Kubernetes Commands:"
echo "  kubectl get pods -n webapp           # List pods in webapp namespace"
echo "  kubectl describe pod <name> -n webapp # Get detailed pod information"
echo "  kubectl logs <pod-name> -n webapp    # View pod logs"
echo "  kubectl get svc -n webapp            # List services"
echo "  kubectl get pvc -n webapp            # List persistent volume claims"
echo ""
echo "Troubleshooting Commands:"
echo "  kubectl get events -n webapp --sort-by='.lastTimestamp'"
echo "  kubectl top pods -n webapp           # Resource usage"
echo "  kubectl get ingress -n webapp        # Ingress status"
echo ""

# Wait for setup to complete with better progress indication
COUNTER=0
while [ ! -f /tmp/setup-complete ]; do
    COUNTER=$((COUNTER + 1))
    case $((COUNTER % 4)) in
        0) echo "⏳ Setting up cluster and deploying broken application..." ;;
        1) echo "🔧 Installing Kubernetes components..." ;;
        2) echo "🚀 Starting minikube cluster..." ;;
        3) echo "📦 Deploying broken application components..." ;;
    esac

    # Give more detailed progress after some time
    if [ $COUNTER -gt 12 ]; then
        echo "📝 Note: Kubernetes cluster startup can take 2-3 minutes on first run"
        echo "🔍 You can check setup progress in another terminal with: docker ps"
    fi

    sleep 5
done

echo "✅ Setup complete!"
echo ""
echo "🔍 Quick cluster status:"
kubectl get nodes
echo ""
echo "📦 Pods in webapp namespace:"
kubectl get pods -n webapp
echo ""
echo "❌ As you can see, several pods are failing!"
echo "Your mission: Fix all the issues and get the application running."
echo ""
echo "🎯 Start by analyzing the pod failures with:"
echo "   kubectl get pods -n webapp"
echo "   kubectl describe pod <failing-pod-name> -n webapp"