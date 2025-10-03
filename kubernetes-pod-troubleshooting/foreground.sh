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

# Wait for setup to complete
while [ ! -f /tmp/setup-complete ]; do
    echo "⏳ Setting up cluster and deploying broken application..."
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