#!/bin/bash

cd /root/app-repo

# Check if branch condition is fixed
if grep -q "branch 'main'" Jenkinsfile && ! grep -q "branch 'master'" Jenkinsfile; then
    echo "Branch condition still uses 'main' instead of 'master'"
    exit 1
fi

# Check if Docker push has some form of authentication or is disabled
if grep -q "docker push" Jenkinsfile && ! grep -q "docker login\|withCredentials\|echo.*push" Jenkinsfile; then
    echo "Docker push still lacks authentication"
    exit 1
fi

# Check if post actions are fixed
if ! grep -q "post {" Jenkinsfile; then
    echo "Post actions section missing"
    exit 1
fi

# Check if cleanup has error handling
if grep -q "docker rmi" Jenkinsfile && ! grep -q "|| true\||| echo" Jenkinsfile; then
    echo "Docker cleanup lacks error handling"
    exit 1
fi

echo "done"
exit 0