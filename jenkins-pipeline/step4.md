# Step 4: Fix Deployment Stage

## Task

Fix the deployment stage configuration including branch conditions, credentials, and deployment commands.

## Instructions

### 1. Fix Branch Condition

The repository uses 'master' branch, not 'main'. Update the when condition:

```groovy
stage('Deploy') {
    when {
        branch 'master'  // Changed from 'main'
    }
    steps {
        // deployment steps
    }
}
```

Or make it more flexible:
```groovy
when {
    anyOf {
        branch 'master'
        branch 'main'
        branch 'production'
    }
}
```

### 2. Fix Docker Push Stage

Add proper Docker authentication:

```groovy
stage('Docker Push') {
    steps {
        script {
            // Method 1: Using withCredentials
            withCredentials([usernamePassword(
                credentialsId: 'docker-hub-creds',
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
            )]) {
                sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                sh "docker push ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
                sh "docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest"
            }
        }
    }
}
```

Or simpler for testing:
```groovy
stage('Docker Push') {
    steps {
        echo "Docker push would happen here"
        sh "docker tag ${APP_NAME}:${BUILD_NUMBER} ${APP_NAME}:latest"
        // Actual push disabled for demo
        // sh "docker push ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
    }
}
```

### 3. Fix Deployment Commands

Since SSH and Kubernetes are not configured, use echo statements:

```groovy
stage('Deploy') {
    when {
        branch 'master'
    }
    steps {
        echo 'Deploying to production...'
        echo "Would deploy version ${BUILD_NUMBER}"
        // Real deployment would use:
        // sshagent(['deploy-ssh-key']) {
        //     sh 'ssh deploy@server "docker pull && docker run..."'
        // }
    }
}
```

### 4. Fix Post Actions

Update post-build actions:

```groovy
post {
    always {
        echo 'Cleaning up...'
        sh "docker rmi ${APP_NAME}:${BUILD_NUMBER} || true"
        cleanWs()
    }
    success {
        echo 'Build succeeded!'
        // emailext can be configured later
    }
    failure {
        echo 'Build failed!'
        // Slack notification would go here
    }
}
```

### 5. Complete Working Pipeline

Here's a complete, working deployment stage:

```groovy
stage('Deploy') {
    when {
        branch 'master'
    }
    steps {
        echo "Deploying ${APP_NAME} version ${BUILD_NUMBER}"
        script {
            // Simulate deployment
            sh """
                echo "Deployment steps:"
                echo "1. Pull image: ${APP_NAME}:${BUILD_NUMBER}"
                echo "2. Stop old container"
                echo "3. Start new container"
                echo "4. Health check"
                echo "Deployment complete!"
            """
        }
    }
}
```

### 6. Environment Variables

Ensure environment variables are properly set:

```groovy
environment {
    DOCKER_REGISTRY = 'docker.io'
    APP_NAME = 'my-app'
    DEPLOY_SERVER = 'production.example.com'
}
```

## Validation

Check the updated Jenkinsfile:
```bash
cd /root/app-repo
grep -A 10 "stage('Deploy')" Jenkinsfile
```

## Checklist

- [ ] Branch condition fixed (main → master)
- [ ] Docker login configured or disabled
- [ ] Tag commands in correct order
- [ ] Deployment steps simplified or mocked
- [ ] Post actions corrected
- [ ] Cleanup commands have error handling
- [ ] Notifications configured or disabled