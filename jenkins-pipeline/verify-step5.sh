#!/bin/bash

cd /root/app-repo

# Check if all major issues are fixed
ERRORS=0

# Check Maven command
if grep -q "mvn clean packages" Jenkinsfile; then
    echo "Maven command still has typo"
    ERRORS=$((ERRORS + 1))
fi

# Check branch condition
if grep -q "when.*branch.*'main'" Jenkinsfile && ! grep -q "master" Jenkinsfile; then
    echo "Branch condition not fixed"
    ERRORS=$((ERRORS + 1))
fi

# Check if Dockerfile exists
if [ ! -f Dockerfile ]; then
    echo "Dockerfile missing"
    ERRORS=$((ERRORS + 1))
fi

# Check if test configuration is fixed
if grep -q "threshold=100" Jenkinsfile; then
    echo "Unrealistic test threshold still present"
    ERRORS=$((ERRORS + 1))
fi

# Check post actions
if ! grep -q "post {" Jenkinsfile; then
    echo "Post actions missing"
    ERRORS=$((ERRORS + 1))
fi

# Test Maven build
if ! mvn clean compile >/dev/null 2>&1; then
    echo "Maven build fails"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
    echo "done"
    exit 0
else
    echo "Found $ERRORS issues still need fixing"
    exit 1
fi