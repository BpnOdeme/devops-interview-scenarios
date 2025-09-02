#!/bin/bash

set -e

echo "Setting up broken Consul service discovery environment..."

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    apt-get update -qq
    apt-get install -y docker.io jq dnsutils curl > /dev/null 2>&1
    systemctl start docker
fi

# Install additional tools
apt-get install -y jq dnsutils curl > /dev/null 2>&1

# Try to start Consul with BROKEN configuration
echo "Starting Consul (will have issues)..."
docker run -d --name consul \
  -p 8500:8500 \
  -p 8600:8600/udp \
  consul agent -server -ui -bootstrap-expect=1 \
  -client=0.0.0.0 \
  -bind=127.0.0.1 2>/dev/null || true  # ISSUE: Bind address incorrect for Docker

# Wait a moment
sleep 2

# Create BROKEN service registration files
cat > /root/web-service.json <<'EOF'
{
  "service": {
    "name": "web",
    "tags": ["primary", "v1"],
    "port": 8080,
    "check": {
      "http": "http://localhost:8081/health",
      "interval": "10s",
      "timeout": "1s"
    },
    "weights": {
      "passing": 10,
      "warning": 1
    }
  }
}
EOF

# Create BROKEN API service registration
cat > /root/api-service.json <<'EOF'
{
  "service": {
    "name": "api",
    "port": 3000,
    "check": {
      "script": "/check.sh",
      "interval": "30s"
    },
    "connect": {
      "sidecar_service": {
        "port": 20000,
        "proxy": {
          "destination_service_name": "database",
          "destination_service_id": "db-1"
        }
      }
    }
  }
}
EOF

# Create BROKEN Consul configuration
cat > /root/consul-config.json <<'EOF'
{
  "datacenter": "dc1",
  "data_dir": "/opt/consul",
  "log_level": "INFO",
  "node_name": "server1",
  "server": true,
  "bootstrap_expect": 3,
  "encrypt": "InvalidBase64Key==",
  "ui": true,
  "client_addr": "127.0.0.1",
  "bind_addr": "127.0.0.1",
  "ports": {
    "dns": 8601
  },
  "connect": {
    "enabled": true,
    "ca_provider": "consul",
    "ca_config": {
      "private_key": ""
    }
  }
}
EOF

# Create BROKEN ACL configuration
cat > /root/acl.json <<'EOF'
{
  "acl": {
    "enabled": true,
    "default_policy": "deny",
    "enable_token_persistence": true,
    "tokens": {
      "master": ""
    }
  }
}
EOF

# Create BROKEN proxy defaults
cat > /root/proxy-defaults.json <<'EOF'
{
  "Kind": "proxy-defaults",
  "Name": "global",
  "Config": {
    "protocol": "http",
    "envoy_prometheus_bind_addr": "0.0.0.0:9102"
  },
  "MeshGateway": {
    "Mode": "remote"
  }
}
EOF

# Create a database service that's referenced but doesn't exist
cat > /root/database-service.json <<'EOF'
{
  "service": {
    "name": "database",
    "port": 5432,
    "check": {
      "tcp": "localhost:5433",
      "interval": "10s"
    }
  }
}
EOF

# Try to register services (will fail)
echo "Attempting to register services (will fail)..."
docker exec consul consul services register /root/web-service.json 2>/dev/null || true
docker exec consul consul services register /root/api-service.json 2>/dev/null || true

# Create sample backend services for testing
docker run -d --name web-backend -p 8080:80 nginx:alpine 2>/dev/null || true
docker run -d --name api-backend -p 3000:3000 -e PORT=3000 node:alpine sh -c "echo 'const http = require(\"http\"); http.createServer((req, res) => res.end(\"API Service\")).listen(3000);' | node" 2>/dev/null || true

# Create reference configuration
mkdir -p /tmp/reference
cat > /tmp/reference/consul-reference.json <<'EOF'
{
  "datacenter": "dc1",
  "data_dir": "/opt/consul",
  "log_level": "INFO",
  "node_name": "consul-server",
  "server": true,
  "bootstrap_expect": 1,
  "ui_config": {
    "enabled": true
  },
  "client_addr": "0.0.0.0",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "connect": {
    "enabled": true
  },
  "ports": {
    "grpc": 8502
  },
  "acl": {
    "enabled": false,
    "default_policy": "allow"
  }
}

// Service Registration Example
{
  "service": {
    "name": "web",
    "tags": ["primary", "v1"],
    "port": 8080,
    "check": {
      "http": "http://localhost:8080/health",
      "interval": "10s",
      "timeout": "5s"
    }
  }
}
EOF

echo ""
echo "Broken Consul environment created!"
echo ""
echo "Issues to fix:"
echo "1. Consul server bind address incorrect for Docker"
echo "2. Bootstrap expect mismatch (expects 3 but only 1 server)"
echo "3. Service health check ports don't match actual services"
echo "4. Health check scripts don't exist"
echo "5. ACL policy blocking without tokens"
echo "6. Invalid encryption key"
echo "7. DNS port non-standard"
echo "8. Service mesh configuration broken"
echo ""
echo "Consul UI should be at: http://localhost:8500 (if it's running)"
echo ""
echo "Start by checking: docker ps"