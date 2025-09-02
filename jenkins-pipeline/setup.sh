#!/bin/bash

set -e

echo "Setting up broken Jenkins CI/CD environment..."

# Install required packages
apt-get update -qq
apt-get install -y docker.io git curl openjdk-11-jdk maven nodejs npm > /dev/null 2>&1

# Start Docker service
systemctl start docker 2>/dev/null || service docker start

# Start Jenkins container
echo "Starting Jenkins container..."
docker run -d --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts > /dev/null 2>&1

# Create application repository
mkdir -p /root/app-repo
cd /root/app-repo
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create BROKEN Jenkinsfile with multiple issues
cat > Jenkinsfile <<'EOF'
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'registry.company.com'  // ISSUE: Wrong registry URL
        DOCKER_CREDENTIALS = 'docker-hub-creds'   // ISSUE: Credentials not configured
        APP_NAME = 'my-app'
        SONAR_HOST = 'http://sonar.company.com'   // ISSUE: Unreachable host
        MAVEN_OPTS = '-Xmx256m'                   // ISSUE: Memory too low
    }
    
    stages {
        stage('Checkout') {
            steps {
                // ISSUE: Branch not specified, credentials missing
                git url: 'https://github.com/company/app.git'
            }
        }
        
        stage('Build') {
            steps {
                // ISSUE: Maven goals incorrect
                sh 'mvn clean packages'  // Typo: should be 'package'
                
                // ISSUE: Dockerfile doesn't exist
                sh 'docker build -t $APP_NAME .'
            }
        }
        
        stage('Test') {
            steps {
                // ISSUE: Test script doesn't exist
                sh './run-tests.sh'
                
                // ISSUE: Wrong test command, threshold too high
                sh 'npm run coverage -- --threshold=100'
                
                // ISSUE: JUnit report path wrong
                junit '**/target/surefire-reports/TEST-*.xml'
            }
        }
        
        stage('Security Scan') {
            steps {
                // ISSUE: SonarQube scanner not installed
                sh 'sonar-scanner -Dsonar.host.url=$SONAR_HOST'
                
                // ISSUE: Missing project key
                sh 'sonar-scanner -Dsonar.projectKey=??? -Dsonar.sources=src'
            }
        }
        
        stage('Docker Push') {
            steps {
                // ISSUE: No docker login
                sh 'docker push $DOCKER_REGISTRY/$APP_NAME:$BUILD_NUMBER'
                
                // ISSUE: Latest tag not created
                sh 'docker tag $APP_NAME:$BUILD_NUMBER $DOCKER_REGISTRY/$APP_NAME:latest'
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'  // ISSUE: Repository uses 'master' branch
            }
            steps {
                // ISSUE: SSH key not configured, wrong path
                sh 'ssh deploy@production.server "bash /deploy/script.sh"'
                
                // ISSUE: Kubernetes config missing
                sh 'kubectl apply -f k8s/deployment.yaml'
            }
        }
    }
    
    post {
        always {
            // ISSUE: Cleanup commands wrong
            sh 'docker rmi $APP_NAME:$BUILD_NUMBER'
        }
        failure {
            // ISSUE: Slack webhook not configured
            slackSend(channel: '#deploys', message: "Build Failed: ${env.BUILD_URL}")
        }
        success {
            // ISSUE: Email configuration missing
            emailext to: 'team@company.com', subject: 'Build Success'
        }
    }
}
EOF

# Create broken pom.xml
cat > pom.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.company</groupId>
    <artifactId>app</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>
    
    <!-- ISSUE: Properties section missing Java version -->
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <!-- ISSUE: Dependencies incomplete -->
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <!-- ISSUE: Version not specified -->
        </dependency>
        
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
            <!-- ISSUE: Scope not set to test -->
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <!-- ISSUE: Version not specified -->
            </plugin>
            
            <!-- ISSUE: Compiler plugin missing -->
        </plugins>
    </build>
</project>
EOF

# Create a simple Java application
mkdir -p src/main/java/com/company
cat > src/main/java/com/company/App.java <<'EOF'
package com.company;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App {
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}
EOF

# Create test file
mkdir -p src/test/java/com/company
cat > src/test/java/com/company/AppTest.java <<'EOF'
package com.company;

import org.junit.Test;
import static org.junit.Assert.*;

public class AppTest {
    @Test
    public void testApp() {
        assertTrue(true);
    }
}
EOF

# Create package.json for frontend tests (wrong location)
cat > package.json <<'EOF'
{
  "name": "app-frontend",
  "version": "1.0.0",
  "scripts": {
    "test": "jest",
    "coverage": "jest --coverage"
  },
  "devDependencies": {
    "jest": "^27.0.0"
  }
}
EOF

# Create Jenkins job configuration with issues
mkdir -p /root/jenkins-config
cat > /root/jenkins-config/config.xml <<'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>CI/CD Pipeline Job</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <!-- ISSUE: GitHub project URL wrong -->
    <com.coravy.hudson.plugins.github.GithubProjectProperty>
      <projectUrl>https://github.com/wrong/repo/</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <!-- ISSUE: Repository URL wrong -->
          <url>https://github.com/company/wrong-app.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <!-- ISSUE: Branch pattern wrong -->
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
  </definition>
  <triggers>
    <!-- ISSUE: Poll SCM too frequent -->
    <hudson.triggers.SCMTrigger>
      <spec>* * * * *</spec>
    </hudson.triggers.SCMTrigger>
  </triggers>
</flow-definition>
EOF

# Create reference Jenkinsfile
mkdir -p /tmp/reference
cat > /tmp/reference/jenkinsfile-reference <<'EOF'
// Reference Jenkins Pipeline Configuration
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_CREDENTIALS = credentials('docker-hub')
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
                sh 'docker build -t $APP_NAME:$BUILD_NUMBER .'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }
        
        stage('Docker Push') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS) {
                        sh "docker push ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
                        sh "docker tag ${APP_NAME}:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${APP_NAME}:latest"
                        sh "docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest"
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'master'
            }
            steps {
                echo 'Deploying to production...'
            }
        }
    }
    
    post {
        always {
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
EOF

# Add files to git
cd /root/app-repo
git add .
git commit -m "Initial broken pipeline" > /dev/null 2>&1

echo ""
echo "Broken Jenkins CI/CD environment created!"
echo ""
echo "Issues to fix:"
echo "1. Jenkinsfile syntax and configuration errors"
echo "2. Maven build configuration problems"
echo "3. Missing Docker configuration and credentials"
echo "4. Test execution failures"
echo "5. Security scanning misconfiguration"
echo "6. Deployment stage issues"
echo "7. Notification system broken"
echo ""
echo "Jenkins is starting at http://localhost:8080"
echo "Check logs: docker logs jenkins"