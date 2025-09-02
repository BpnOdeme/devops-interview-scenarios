# Step 3: Fix Testing and Security

## Task

Fix the test execution and security scanning stages in the pipeline.

## Instructions

### 1. Fix Test Stage

Create the missing test script:
```bash
cat > /root/app-repo/run-tests.sh <<'EOF'
#!/bin/bash
echo "Running unit tests..."
mvn test
echo "Tests completed"
EOF
chmod +x /root/app-repo/run-tests.sh
```

Update the Jenkinsfile test stage:
```groovy
stage('Test') {
    steps {
        sh 'mvn test'
        junit '**/target/surefire-reports/*.xml'
    }
}
```

Or if you want to keep the script:
```groovy
stage('Test') {
    steps {
        sh './run-tests.sh'
        junit 'target/surefire-reports/*.xml'
    }
}
```

### 2. Fix Frontend Testing

Either remove NPM tests or move them to appropriate location:

Option A - Remove NPM tests from Java pipeline:
```groovy
// Remove this line:
// sh 'npm run coverage -- --threshold=100'
```

Option B - Create frontend directory and move tests:
```bash
mkdir -p /root/app-repo/frontend
mv /root/app-repo/package.json /root/app-repo/frontend/
cd /root/app-repo/frontend
npm install
```

### 3. Fix Security Scanning

Since SonarQube server is not available, either:

Option A - Comment out or use echo for demo:
```groovy
stage('Security Scan') {
    steps {
        echo 'Security scanning would run here'
        // Actual scanning disabled for demo
        // sh 'sonar-scanner -Dsonar.host.url=$SONAR_HOST'
    }
}
```

Option B - Use alternative security scanning:
```groovy
stage('Security Scan') {
    steps {
        // Run dependency check
        sh 'mvn dependency:tree'
        // Could add OWASP dependency check
        echo 'Security scan completed'
    }
}
```

Option C - Configure SonarQube properly:
```groovy
stage('Security Scan') {
    steps {
        script {
            // Use SonarQube environment
            withSonarQubeEnv('SonarQube') {
                sh 'mvn sonar:sonar -Dsonar.projectKey=my-app'
            }
        }
    }
}
```

### 4. Add Test Reports

Configure proper test reporting:
```groovy
post {
    always {
        junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
    }
}
```

### 5. Create Simple Test Configuration

Add test properties to pom.xml:
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>2.22.2</version>
            <configuration>
                <testFailureIgnore>false</testFailureIgnore>
            </configuration>
        </plugin>
    </plugins>
</build>
```

## Validation

Test the changes:
```bash
cd /root/app-repo
./run-tests.sh
ls -la target/surefire-reports/
```

## Checklist

- [ ] Test script created and executable
- [ ] JUnit report path corrected
- [ ] NPM tests removed or relocated
- [ ] Coverage threshold adjusted or removed
- [ ] Security scanning fixed or disabled
- [ ] Test reporting configured
- [ ] Maven surefire plugin configured