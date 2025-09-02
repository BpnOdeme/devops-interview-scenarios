#!/bin/bash

cd /root/infrastructure

# Check if circular dependency is fixed
if terraform validate 2>&1 | grep -q "Cycle"; then
    echo "Circular dependency still exists"
    exit 1
fi

# Check if configuration validates
if ! terraform validate > /dev/null 2>&1; then
    echo "Configuration still has validation errors"
    exit 1
fi

echo "done"
exit 0