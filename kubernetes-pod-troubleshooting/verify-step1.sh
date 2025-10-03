#!/bin/bash

# Verification script for Step 1: Diagnose Pod Failures

echo "Verifying Step 1: Pod Diagnosis..."

# Check if student has identified the main issues
FAILED_PODS=$(kubectl get pods -n webapp --no-headers | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff|Pending)" | wc -l)

if [ $FAILED_PODS -gt 0 ]; then
    echo "✅ Successfully identified failing pods"
    echo "Found $FAILED_PODS pods with issues"

    # Check if they've looked at pod descriptions
    echo "Pod statuses:"
    kubectl get pods -n webapp --no-headers | while read pod rest; do
        STATUS=$(echo $rest | awk '{print $3}')
        echo "  $pod: $STATUS"
    done

    echo ""
    echo "✅ Step 1 verification passed!"
    echo "You have successfully identified the pod failures."
    echo "Proceed to Step 2 to fix service communication issues."
    exit 0
else
    echo "❌ No failing pods found. This might indicate the issues were already fixed."
    echo "Make sure you've examined the pod statuses and identified the root causes."
    exit 1
fi