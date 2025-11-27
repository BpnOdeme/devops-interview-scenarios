# Docker Compose Microservices Troubleshooting

## Overview

A comprehensive Docker Compose troubleshooting scenario designed to test middle-level DevOps engineering skills. This interactive challenge presents a completely broken microservices infrastructure that you must systematically diagnose and fix.

## Scenario Background

You've been assigned to investigate and repair a production-like Docker Compose deployment that was hastily abandoned by a previous team. The application consists of four services that should work together but currently nothing functions correctly.

## Architecture Components

### Services

1. **Frontend** (Nginx - Port 80)
   - Serves static HTML content
   - Reverse proxies API requests
   - Entry point for user traffic

2. **API** (Node.js - Port 3000)
   - Backend business logic service
   - Connects to database and cache
   - Provides REST API endpoints
   - Health check monitoring

3. **Database** (MySQL 8.0 - Port 3306)
   - Persistent data storage
   - User and application database
   - Credential-based authentication

4. **Cache** (Redis 6 - Port 6379)
   - Session management
   - Data caching layer
   - Password-protected access

### Intended Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│           Docker Bridge Network                  │
│                                                  │
│   ┌─────────┐         ┌─────────┐              │
│   │Frontend │◄───────►│   API   │              │
│   │ nginx   │         │ node:14 │              │
│   │ :80     │         │ :3000   │              │
│   └─────────┘         └────┬─┬──┘              │
│                            │ │                  │
│                    ┌───────┘ └────────┐         │
│                    ▼                  ▼         │
│               ┌─────────┐        ┌────────┐    │
│               │Database │        │ Cache  │    │
│               │ MySQL   │        │ Redis  │    │
│               │ :3306   │        │ :6379  │    │
│               └─────────┘        └────────┘    │
└─────────────────────────────────────────────────┘
```

## What's Broken

Multiple infrastructure and configuration issues prevent the stack from functioning:

- ❌ **File Permissions**: docker-compose.yml is not accessible
- ❌ **Network Configuration**: Services on incompatible networks cannot communicate
- ❌ **Network Driver**: Incorrect driver for single-host deployment
- ❌ **Environment Variables**: Service references don't match actual service names
- ❌ **Port Mappings**: Wrong ports or reversed port mappings
- ❌ **Database Credentials**: Missing or mismatched user configuration
- ❌ **Volume Mounts**: Application code not properly mounted
- ❌ **Nginx Configuration**: Proxy pointing to wrong service/port
- ❌ **Pre-existing Networks**: Conflicting Docker networks

## Challenge Structure

### Step 1: Initial Investigation and Access
- Fix file permission issues
- Analyze the infrastructure setup
- Identify configuration problems
- Document all discovered issues

### Step 2: Fix Network Configuration
- Resolve network isolation issues
- Fix network driver incompatibility
- Ensure proper service-to-service communication
- Remove conflicting networks

### Step 3: Fix Service Configuration
- Correct environment variables
- Fix port mappings
- Configure database credentials
- Fix nginx proxy configuration
- Set up volume mounts

### Step 4: Deploy and Test
- Start the complete stack
- Perform comprehensive testing
- Validate end-to-end functionality
- Verify inter-service communication

## Difficulty Level

**Target Audience**: Middle-Level DevOps Engineers
**Estimated Time**: 30-40 minutes
**Difficulty**: Intermediate

### Skills Tested

- Docker Compose configuration and troubleshooting
- Container networking and service discovery
- Environment variable management
- Systematic debugging methodologies
- Log analysis and interpretation
- Configuration validation
- End-to-end testing practices

## Prerequisites

### Required Knowledge
- Docker and Docker Compose fundamentals
- Basic Linux command line
- Understanding of microservices architecture
- Networking basics (DNS, ports, connectivity)
- Text editing with nano or vim

### System Requirements
- Docker Engine 20.10+
- Docker Compose 1.29+
- Linux environment (or Ubuntu-based Killercoda)
- 4GB RAM minimum
- curl, grep, and basic Unix tools

## Quick Start (Local Development)

### 1. Clone the Repository
```bash
git clone <repository-url>
cd docker-compose-microservices
```

### 2. Run Setup Script
```bash
bash setup.sh
```

This creates a broken infrastructure at `/root/microservices/` with intentional issues to fix.

### 3. Start Troubleshooting
```bash
cd /root/microservices
# Follow the step-by-step instructions in intro.md and stepX.md files
```

### 4. Validate Your Fixes
```bash
# After each step, run the corresponding verification script
bash verify-step1.sh
bash verify-step2.sh
bash verify-step3.sh
bash verify-step4.sh
```

## File Structure

```
docker-compose-microservices/
├── README.md                    # This file
├── intro.md                     # Scenario introduction
├── step1.md                     # Investigation tasks
├── step2.md                     # Network configuration fixes
├── step3.md                     # Service configuration fixes
├── step4.md                     # Deployment and testing
├── finish.md                    # Completion summary
├── setup.sh                     # Creates broken environment
├── foreground.sh                # Killercoda startup script
├── verify-step1.sh              # Validates Step 1
├── verify-step2.sh              # Validates Step 2
├── verify-step3.sh              # Validates Step 3
├── verify-step4.sh              # Validates Step 4 (end-to-end)
├── index.json                   # Killercoda configuration
├── api/
│   ├── index.js                 # Node.js API code
│   └── package.json             # Node.js dependencies
├── nginx/
│   └── default.conf             # Nginx configuration
├── html/
│   └── index.html               # Frontend HTML
└── KILLERCODE_SOLUTION.md       # Detailed solution guide
```

## API Endpoints

Once the stack is successfully deployed:

### Health Checks
```bash
# API health check
curl http://localhost:3000/health
# Response: {"status":"healthy","service":"api"}

# Frontend
curl http://localhost/
# Response: HTML content
```

### API Endpoints
```bash
# Root endpoint
curl http://localhost:3000/
# Response: {"message":"API is running!"}

# API endpoint
curl http://localhost:3000/api
# Response: {"message":"API is working!"}

# Frontend-proxied endpoint (critical test)
curl http://localhost/api
# Response: {"message":"API is working!"}
```

### Database
```bash
# Test MySQL connection
docker-compose exec db mysql -u appuser -papppass -e "SELECT 1;"
```

### Cache
```bash
# Test Redis connection
docker-compose exec cache redis-cli -a secretpass ping
# Response: PONG
```

## Troubleshooting Tips

### Common Commands

```bash
# Validate YAML configuration
docker-compose config

# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs api

# Check Docker networks
docker network ls

# Inspect a specific network
docker network inspect microservices_app-network

# Test connectivity between services
docker-compose exec api ping -c 2 db
```

### Common Issues

1. **Cannot read docker-compose.yml**
   - Solution: Check file permissions with `ls -la`, fix with `chmod 644`

2. **Services cannot communicate**
   - Solution: Ensure services share at least one common Docker network

3. **Wrong network driver**
   - Solution: Use `bridge` driver for single-host deployments, not `overlay`

4. **Database connection failures**
   - Solution: Verify DB_HOST matches database service name, check credentials

5. **Frontend cannot reach API**
   - Solution: Check nginx proxy_pass configuration, ensure correct service name and port

## Success Criteria

Your troubleshooting is successful when:

- ✅ All 4 services are running (no Restarting/Exited states)
- ✅ docker-compose.yml is readable and valid
- ✅ All services can communicate over Docker network
- ✅ Database accepts connections with correct credentials
- ✅ Redis responds to authenticated ping
- ✅ API health checks return healthy status
- ✅ Frontend serves HTML content
- ✅ Frontend successfully proxies /api requests to backend
- ✅ All verification scripts pass

## Solution

A complete solution with step-by-step fixes is available in `KILLERCODE_SOLUTION.md`. However, we strongly recommend attempting the challenge yourself first for maximum learning benefit.

## Learning Outcomes

After completing this scenario, you will:

- Understand Docker Compose networking in depth
- Master systematic troubleshooting methodologies
- Know how to debug multi-service applications
- Understand environment variable configuration
- Be proficient in reading and analyzing container logs
- Know how to validate distributed system functionality
- Understand service discovery and DNS in Docker
- Be able to fix common Docker Compose configuration issues

## Real-World Relevance

This scenario simulates actual production issues:

- **Configuration Drift**: Settings that worked before stop working after changes
- **Network Isolation**: Services incorrectly segmented
- **Credential Mismatches**: Hardcoded values that don't align
- **Port Conflicts**: Wrong port mappings
- **Missing Configurations**: Incomplete environment setup
- **Proxy Misconfiguration**: Incorrect routing in reverse proxies

DevOps engineers regularly encounter these issues in:
- Development environment setup
- Production deployments
- Infrastructure migrations
- Multi-team collaboration environments
- Legacy system maintenance

## Additional Resources

### Docker Documentation
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)

### Related Scenarios
- Kubernetes Pod Troubleshooting
- Terraform State Management
- Nginx Load Balancer Configuration
- Jenkins Pipeline Debugging

## Contributing

Found an issue or have suggestions? Please open an issue or submit a pull request.

## License

MIT License - See LICENSE file for details

---

**Ready to start?** Run `bash setup.sh` and begin your troubleshooting journey!
