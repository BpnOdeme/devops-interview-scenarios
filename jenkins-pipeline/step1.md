# Step 1: Analyze Pipeline Issues

## Task

Review the Jenkins pipeline configuration and identify all issues that need to be fixed.

## Instructions

1. Navigate to the project directory:
   ```bash
   cd /root/app-repo
   ```

2. Review the Jenkinsfile:
   ```bash
   cat Jenkinsfile
   ```

3. Check the Maven configuration:
   ```bash
   cat pom.xml
   ```

4. List project structure:
   ```bash
   find . -type f -name "*.java" -o -name "*.xml" -o -name "*.json" | head -20
   ```

5. Check the reference pipeline:
   ```bash
   cat /tmp/reference/jenkinsfile-reference
   ```

## Issues to Identify

### Pipeline Configuration
- [ ] Docker registry URL incorrect
- [ ] Docker credentials not configured
- [ ] Environment variables misconfigured
- [ ] Memory settings too low

### Build Stage
- [ ] Maven command has typo (`packages` vs `package`)
- [ ] Dockerfile missing
- [ ] Build dependencies incomplete

### Test Stage
- [ ] Test script `run-tests.sh` doesn't exist
- [ ] NPM test commands in wrong location
- [ ] Coverage threshold unrealistic (100%)
- [ ] JUnit report path incorrect

### Security Stage
- [ ] SonarQube scanner not available
- [ ] SonarQube host unreachable
- [ ] Project key missing

### Deployment Stage
- [ ] Branch name mismatch (`main` vs `master`)
- [ ] SSH credentials not configured
- [ ] Kubernetes config missing
- [ ] Deploy script path wrong

### Notifications
- [ ] Slack webhook not configured
- [ ] Email configuration missing

## Common Pipeline Patterns

### Proper Checkout
```groovy
stage('Checkout') {
    steps {
        checkout scm  // Uses job's SCM configuration
    }
}
```

### Maven Build
```groovy
stage('Build') {
    steps {
        sh 'mvn clean package'  // Note: 'package' not 'packages'
    }
}
```

### Docker Operations
```groovy
script {
    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials-id') {
        // Docker operations
    }
}
```

## Documentation

Make notes of all issues found. You'll fix them in the following steps.