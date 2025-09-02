# Step 2: Fix Consul Server

## Task

Fix the Consul server configuration and get it running properly.

## Instructions

### 1. Stop and Remove Broken Consul Container

```bash
docker stop consul 2>/dev/null
docker rm consul 2>/dev/null
```

### 2. Start Consul with Correct Configuration

Fix the bind address and bootstrap issues:

```bash
docker run -d --name consul \
  -p 8500:8500 \
  -p 8600:8600/udp \
  -p 8600:8600/tcp \
  consul agent \
  -server \
  -ui \
  -bootstrap-expect=1 \
  -client=0.0.0.0 \
  -bind='{{ GetInterfaceIP "eth0" }}' \
  -datacenter=dc1 \
  -node=consul-server
```

Or use a simpler approach for single node:

```bash
docker run -d --name consul \
  -p 8500:8500 \
  -p 8600:8600/udp \
  -p 8600:8600/tcp \
  consul agent \
  -dev \
  -ui \
  -client=0.0.0.0
```

### 3. Verify Consul is Running

```bash
# Check container status
docker ps | grep consul

# Check Consul members
docker exec consul consul members

# Check API
curl http://localhost:8500/v1/status/leader

# Access UI
echo "Consul UI: http://localhost:8500/ui"
```

### 4. Create Proper Configuration File (Alternative)

If you prefer configuration file approach:

```bash
cat > /root/consul-server.json <<'EOF'
{
  "datacenter": "dc1",
  "data_dir": "/consul/data",
  "log_level": "INFO",
  "node_name": "consul-server",
  "server": true,
  "bootstrap_expect": 1,
  "ui_config": {
    "enabled": true
  },
  "client_addr": "0.0.0.0",
  "bind_addr": "0.0.0.0",
  "advertise_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "ports": {
    "dns": 8600,
    "http": 8500,
    "grpc": 8502
  }
}
EOF

# Run with config file
docker run -d --name consul \
  -v /root/consul-server.json:/consul/config/consul.json:ro \
  -p 8500:8500 \
  -p 8600:8600/udp \
  -p 8600:8600/tcp \
  consul agent -config-dir=/consul/config
```

### 5. Fix Network Issues

Ensure Consul can communicate properly:

```bash
# Check network
docker network ls

# If needed, create custom network
docker network create consul-net

# Restart Consul on custom network
docker stop consul && docker rm consul
docker run -d --name consul \
  --network consul-net \
  -p 8500:8500 \
  -p 8600:8600/udp \
  -p 8600:8600/tcp \
  consul agent -dev -ui -client=0.0.0.0
```

## Validation

Test that Consul is working:

```bash
# Check members
docker exec consul consul members

# List datacenters
curl http://localhost:8500/v1/catalog/datacenters

# Check nodes
curl http://localhost:8500/v1/catalog/nodes

# DNS test
dig @127.0.0.1 -p 8600 consul.service.consul
```

## Expected Output

```
Node           Address          Status  Type    Build   Protocol  DC   Segment
consul-server  172.17.0.2:8301  alive   server  1.16.0  2         dc1  <all>
```

## Troubleshooting

If Consul won't start:
- Check ports are free: `netstat -tulpn | grep -E "8500|8600"`
- Check Docker logs: `docker logs consul`
- Ensure no other Consul instances: `ps aux | grep consul`

## Checklist

- [ ] Removed broken Consul container
- [ ] Started Consul with correct bind address
- [ ] Bootstrap expect set to 1 for single node
- [ ] Client address set to 0.0.0.0 for external access
- [ ] UI is accessible at http://localhost:8500
- [ ] DNS is working on port 8600