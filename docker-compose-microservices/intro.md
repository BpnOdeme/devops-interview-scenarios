# Docker Compose Microservices Troubleshooting

## Scenario Overview

You've been assigned as the DevOps engineer to investigate and fix a production-like Docker Compose deployment that's completely broken. The previous team left in a hurry, and the application is down.

The system architecture consists of:

- **Frontend**: Nginx serving static web content and reverse proxying API requests
- **API**: Node.js backend service handling business logic
- **Database**: MySQL 8.0 for persistent data storage
- **Cache**: Redis 6 for session management and caching

## The Problem

The development team deployed this stack to a staging environment, but nothing is working:

- Services cannot communicate with each other
- Docker Compose file has permission issues preventing access
- Database connections are failing with authentication errors
- Redis connectivity is broken
- Frontend cannot reach the API backend
- Multiple network configuration issues
- Environment variables are misconfigured
- Application code isn't properly mounted

## Your Mission

You need to systematically diagnose and fix **all infrastructure and configuration issues**. This is a realistic troubleshooting scenario that tests your ability to:

1. **Analyze Complex Systems**: Understand service dependencies and network topology
2. **Debug Docker Compose**: Identify misconfigurations in multi-service setups
3. **Fix Network Issues**: Resolve service communication problems
4. **Correct Environment Configuration**: Fix environment variables and service references
5. **Validate Components**: Ensure all services have proper configurations
6. **Test End-to-End**: Verify the complete stack is functional

## Challenge Level

**Difficulty**: Intermediate
**Time Estimate**: 30-40 minutes
**Skills Required**:
- Docker Compose configuration
- Container networking
- Service discovery and DNS
- Environment variable management
- Debugging distributed systems
- Linux permissions and file management

## Available Tools

You have full access to:
- `docker-compose` - Orchestrate and manage multi-container applications
- `docker` - Manage containers, networks, and volumes
- `curl` - Test HTTP endpoints
- `nano/vim` - Edit configuration files
- `ls/cat/grep` - Investigate files and logs
- Docker Compose documentation and online resources

## Important Notes

- **Focus on Infrastructure**: You're responsible for Docker Compose configuration, networking, and service connectivity
- **Application Code**: The API code is provided and should work once infrastructure is fixed
- **Systematic Approach**: Document issues as you find them
- **Production Mindset**: Think about how these issues would manifest in real production systems

## Success Criteria

Your troubleshooting will be considered successful when:

- All services start without errors
- Services can communicate across the proper networks
- Database and cache are accessible from the API
- Frontend can proxy requests to the API
- No port conflicts or permission issues exist
- The stack passes all verification tests

## Getting Started

The broken infrastructure is located at `/root/microservices/`

Start by investigating the current state of the system. Look for:
- File permissions issues
- Network topology problems
- Service naming inconsistencies
- Port configuration errors
- Missing or incorrect configurations

**Remember**: Don't rush to fix things. First understand what's broken and why. A good DevOps engineer investigates before implementing solutions.

Click **START** to begin your troubleshooting journey!
