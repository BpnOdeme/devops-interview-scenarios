#!/bin/bash

# Check if user has fixed permissions and read the docker-compose.yml
if [ -r /root/microservices/docker-compose.yml ]; then
    # Check if file is readable with proper permissions
    PERMS=$(stat -c "%a" /root/microservices/docker-compose.yml 2>/dev/null || stat -f "%A" /root/microservices/docker-compose.yml 2>/dev/null)
    if [[ "$PERMS" == "644" ]] || [[ "$PERMS" == "664" ]] || [[ "$PERMS" == "666" ]]; then
        echo "done"
        exit 0
    fi
fi

echo "Please fix the permissions on docker-compose.yml (chmod 644)"
exit 1