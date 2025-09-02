#!/bin/bash

cd /root/app-repo

# Check if test script exists or tests are configured
if [ ! -f run-tests.sh ] && ! grep -q "mvn test" Jenkinsfile; then
    echo "Test execution not properly configured"
    exit 1
fi

# Check if test script is executable
if [ -f run-tests.sh ] && [ ! -x run-tests.sh ]; then
    echo "Test script is not executable"
    exit 1
fi

# Check if unrealistic coverage threshold is removed or adjusted
if grep -q "threshold=100" Jenkinsfile; then
    echo "Coverage threshold still set to unrealistic 100%"
    exit 1
fi

# Check if JUnit path is fixed
if grep -q "\*\*/target/surefire-reports/TEST-\*.xml" Jenkinsfile; then
    echo "JUnit report path still has incorrect pattern"
    exit 1
fi

echo "done"
exit 0