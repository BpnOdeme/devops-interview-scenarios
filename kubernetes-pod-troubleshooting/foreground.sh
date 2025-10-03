#!/bin/bash

# Foreground setup for Kubernetes troubleshooting scenario

echo "🚀 Welcome to Kubernetes Pod Troubleshooting!"
echo ""
echo "You are in a Kubernetes cluster with broken applications that need fixing."
echo ""
echo "Here are the essential commands you'll need:"
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
echo "  kubectl get ingress -n webapp        # Ingress status"
echo ""
echo "📦 Deploying broken application components..."
echo "This will take about 30 seconds..."
echo ""

# Simple wait for setup
sleep 30

echo "✅ Setup complete!"
echo ""
echo "🔍 Quick cluster status:"
kubectl get nodes 2>/dev/null || echo "Cluster starting..."
echo ""
echo "📦 Pods in webapp namespace:"
kubectl get pods -n webapp 2>/dev/null || echo "Pods deploying..."
echo ""
echo "❌ As you can see, several pods are failing!"
echo "Your mission: Fix all the issues and get the application running."
echo ""
echo "🎯 Start by analyzing the pod failures with:"
echo "   kubectl get pods -n webapp"
echo "   kubectl describe pod <failing-pod-name> -n webapp"