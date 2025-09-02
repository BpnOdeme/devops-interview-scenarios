# Step 5: Test the Pipeline

## Task

Validate the complete pipeline and ensure it can run successfully.

## Instructions

### 1. Validate Pipeline Syntax

Use Jenkins Pipeline linter (if available):
```bash
# Check Jenkinsfile syntax
cat /root/app-repo/Jenkinsfile | head -50
```

Common syntax checks:
- All stages have steps
- Brackets are balanced
- Strings are properly quoted
- Environment variables use correct syntax

### 2. Test Build Locally

Test the build process:
```bash
cd /root/app-repo

# Test Maven build
mvn clean package

# Test Docker build
docker build -t my-app:test .

# List Docker images
docker images | grep my-app
```

### 3. Create Final Working Pipeline

Your final Jenkinsfile should look similar to:

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        APP_NAME = 'my-app'
        MAVEN_OPTS = '-Xmx1024m'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package'
                sh "docker build -t ${APP_NAME}:${BUILD_NUMBER} ."
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
                junit 'target/surefire-reports/*.xml'
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Security scanning would run here'
                sh 'mvn dependency:tree'
            }
        }
        
        stage('Docker Push') {
            steps {
                echo "Would push ${APP_NAME}:${BUILD_NUMBER} to registry"
                sh "docker tag ${APP_NAME}:${BUILD_NUMBER} ${APP_NAME}:latest"
            }
        }
        
        stage('Deploy') {
            when {
                branch 'master'
            }
            steps {
                echo "Deploying ${APP_NAME} version ${BUILD_NUMBER}"
            }
        }
    }
    
    post {
        always {
            sh "docker rmi ${APP_NAME}:${BUILD_NUMBER} || true"
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### 4. Jenkins Job Configuration

If you have access to Jenkins UI:

1. Access Jenkins at http://localhost:8080
2. Create a new Pipeline job
3. Configure SCM to point to /root/app-repo
4. Set Pipeline script from SCM
5. Save and run the pipeline

### 5. Simulate Pipeline Execution

Simulate the pipeline stages:
```bash
cd /root/app-repo

echo "=== Stage: Checkout ==="
git status

echo "=== Stage: Build ==="
mvn clean package
docker build -t my-app:1 .

echo "=== Stage: Test ==="
mvn test

echo "=== Stage: Security ==="
mvn dependency:tree

echo "=== Stage: Docker Operations ==="
docker tag my-app:1 my-app:latest
docker images | grep my-app

echo "=== Stage: Deploy ==="
echo "Deployment simulation complete"

echo "=== Post: Cleanup ==="
docker rmi my-app:1 || true
```

### 6. Final Validation Checklist

Verify all fixes are in place:

- [ ] Jenkinsfile has valid syntax
- [ ] All stages have proper steps
- [ ] Maven commands are correct
- [ ] Docker operations are properly configured
- [ ] Tests can execute
- [ ] Security scanning is handled
- [ ] Deployment has correct branch condition
- [ ] Post actions include cleanup
- [ ] Error handling is in place

## Success Indicators

✅ Maven build completes successfully
✅ Docker image is created
✅ Tests pass
✅ No syntax errors in pipeline
✅ Pipeline can handle failures gracefully

## Troubleshooting

If issues persist:
1. Check Maven: `mvn --version`
2. Check Docker: `docker --version`
3. Review logs: `docker logs jenkins`
4. Validate syntax carefully
5. Test each stage independently