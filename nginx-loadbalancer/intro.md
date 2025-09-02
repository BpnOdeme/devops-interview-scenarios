# Nginx Load Balancer Troubleshooting

## Scenario Overview

You've been called to investigate a production issue where the Nginx load balancer is not working correctly. The system consists of:

- 1 Nginx server acting as a load balancer
- 3 backend application servers
- Health check monitoring

## Your Mission

1. **Identify the Problem**: The load balancer is returning errors. Find out why.
2. **Fix the Configuration**: Correct any misconfigurations in the Nginx setup.
3. **Verify Load Balancing**: Ensure traffic is properly distributed across all backend servers.
4. **Implement Health Checks**: Make sure unhealthy backends are automatically removed from the pool.

## Available Tools

- `nginx -t` - Test Nginx configuration
- `curl` - Test HTTP endpoints
- `systemctl` - Manage services
- `tail -f` - Monitor logs in real-time
- `nano/vim` - Edit configuration files

## Success Criteria

- Nginx configuration is valid
- All backend servers receive traffic
- Health checks are working
- Load balancing algorithm is functioning correctly

Click **START** to begin the troubleshooting!