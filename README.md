# DevOps Interview Scenarios for Killercoda

This repository contains interactive DevOps interview scenarios designed to run on the Killercoda platform. These scenarios provide hands-on challenges that test real-world DevOps skills and troubleshooting abilities.

## Available Scenarios

### 1. Nginx Load Balancer Troubleshooting
- **Path**: `/nginx-loadbalancer`
- **Difficulty**: Intermediate
- **Duration**: 25 minutes
- **Skills Tested**: 
  - Nginx configuration debugging
  - Load balancing concepts
  - Health check implementation
  - Log analysis

### 2. Docker Compose Microservices Troubleshooting
- **Path**: `/docker-compose-microservices`
- **Difficulty**: Intermediate
- **Duration**: 30 minutes
- **Skills Tested**:
  - Docker Compose configuration
  - Container networking
  - Service dependencies
  - Environment variables
  - Multi-container debugging

### 3. Jenkins CI/CD Pipeline Troubleshooting
- **Path**: `/jenkins-pipeline`
- **Difficulty**: Intermediate
- **Duration**: 35 minutes
- **Skills Tested**:
  - Jenkins pipeline syntax
  - CI/CD best practices
  - Maven build configuration
  - Docker integration
  - Testing and deployment stages

## How to Use These Scenarios

### For Killercoda Integration

1. Fork this repository to your GitHub account
2. Go to [Killercoda Creator](https://killercoda.com/creator)
3. Connect your GitHub account
4. Select this repository
5. Your scenarios will be automatically available at `https://killercoda.com/[your-username]`

### Repository Structure

Each scenario follows the Killercoda standard structure:
```
scenario-name/
├── index.json          # Scenario configuration
├── intro.md           # Introduction shown to users
├── setup.sh           # Background setup script
├── foreground.sh      # Foreground initialization
├── step1.md           # Step 1 instructions
├── verify-step1.sh    # Step 1 verification
├── step2.md           # Step 2 instructions
├── verify-step2.sh    # Step 2 verification
├── finish.md          # Completion message
└── assets/            # Additional files (if needed)
```

## Scenario Development Guidelines

### Best Practices

1. **Clear Objectives**: Each scenario should have well-defined learning objectives
2. **Progressive Difficulty**: Steps should build on each other
3. **Realistic Problems**: Simulate actual production issues
4. **Automated Verification**: Use verification scripts to check solutions
5. **Helpful Hints**: Provide guidance without giving away the solution

### Testing Locally

Before pushing to Killercoda:
1. Test setup scripts in a clean Ubuntu 22.04 environment
2. Verify all commands work as expected
3. Ensure verification scripts accurately check solutions
4. Test the complete flow from start to finish

## Contributing

To add a new scenario:
1. Create a new directory with the scenario name
2. Follow the standard Killercoda structure
3. Include all required files (index.json, intro.md, setup.sh, etc.)
4. Test thoroughly before submitting
5. Update this README with scenario details

## Killercoda Features Used

- **Environment**: Ubuntu 22.04
- **UI Layout**: Terminal-based interface
- **Verification**: Automated step verification
- **Assets**: Pre-configured files for reference
- **Background Scripts**: Automatic environment setup

## License

MIT License - Feel free to use and modify for your interview processes.

## Support

For issues or questions:
- Open an issue in this repository
- Check [Killercoda Documentation](https://killercoda.com/docs)

## Roadmap

Planned scenarios:
- [ ] Docker Container Debugging
- [ ] Kubernetes Pod Troubleshooting
- [ ] CI/CD Pipeline Fix
- [ ] Database Performance Tuning
- [ ] Security Incident Response
- [ ] Monitoring and Alerting Setup