#!/bin/bash

# Check if user has reviewed the files
if [ -f /tmp/pipeline_analyzed ]; then
    echo "done"
    exit 0
fi

# Check if user has viewed the Jenkinsfile
if grep -q "Jenkinsfile\|pom.xml" ~/.bash_history 2>/dev/null; then
    touch /tmp/pipeline_analyzed
    echo "done"
    exit 0
fi

# Check if user is in the correct directory
if pwd | grep -q "app-repo"; then
    touch /tmp/pipeline_analyzed
    echo "done"
    exit 0
fi

echo "Please review the Jenkinsfile and pom.xml files"
exit 1