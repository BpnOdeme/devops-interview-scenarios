# Jenkins CI/CD Pipeline Troubleshooting

## Scenario Overview

You've joined a development team that's struggling with their Jenkins CI/CD pipeline. The pipeline has multiple failures and misconfigurations that are preventing successful builds and deployments. The team needs your expertise to fix these issues and get their continuous delivery process working again.

## The System

The pipeline is designed to:
- Build a Java application with Maven
- Run unit and integration tests
- Perform security scanning with SonarQube
- Build and push Docker images
- Deploy to production environments

## Current Problems

The team reports:
- ❌ Build stage fails with missing dependencies
- ❌ Tests cannot run due to missing scripts
- ❌ Docker registry authentication not working
- ❌ Security scanning misconfigured
- ❌ Deployment credentials missing
- ❌ Notification system broken
- ❌ Pipeline syntax errors throughout

## Your Mission

1. **Analyze the Pipeline**: Review the Jenkinsfile and identify all issues
2. **Fix Build Configuration**: Resolve Maven and Docker build problems
3. **Repair Testing**: Fix test execution and coverage requirements
4. **Configure Security**: Set up proper security scanning
5. **Fix Deployment**: Resolve credential and deployment issues
6. **Test End-to-End**: Ensure the pipeline runs successfully

## Available Tools

- `cat/nano/vim` - View and edit files
- `docker` - Container management
- `mvn` - Maven build tool
- `git` - Version control
- `curl` - Test Jenkins API
- Jenkins UI at `http://localhost:8080`

## Files to Review

- `/root/app-repo/Jenkinsfile` - Main pipeline definition
- `/root/app-repo/pom.xml` - Maven configuration
- `/root/jenkins-config/config.xml` - Jenkins job configuration

## Success Criteria

- Pipeline syntax is valid
- All stages can execute without errors
- Proper credentials and configurations in place
- Build artifacts are created successfully
- Deployment stage is properly gated
- Notifications work correctly

## Jenkins Access

Once Jenkins is running:
- URL: `http://localhost:8080`
- Initial admin password: Check Docker logs
- Command: `docker logs jenkins 2>&1 | grep -A 5 "initial"` 

Click **START** to begin troubleshooting!