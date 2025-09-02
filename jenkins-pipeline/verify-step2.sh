#!/bin/bash

cd /root/app-repo

# Check if Dockerfile exists
if [ ! -f Dockerfile ]; then
    echo "Dockerfile is missing"
    exit 1
fi

# Check if pom.xml has Java version
if ! grep -q "maven.compiler.source" pom.xml; then
    echo "Maven compiler source version not set in pom.xml"
    exit 1
fi

# Check if Jenkinsfile has correct Maven command
if grep -q "mvn clean packages" Jenkinsfile; then
    echo "Maven command still has typo (packages instead of package)"
    exit 1
fi

# Check if MAVEN_OPTS is increased
if grep -q "MAVEN_OPTS.*256m" Jenkinsfile; then
    echo "MAVEN_OPTS memory still too low"
    exit 1
fi

echo "done"
exit 0