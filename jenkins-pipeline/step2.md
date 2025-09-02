# Step 2: Fix Build Configuration

## Task

Fix the build-related issues in both the Jenkinsfile and Maven configuration.

## Instructions

### 1. Fix Maven Configuration (pom.xml)

Edit the pom.xml file:
```bash
nano /root/app-repo/pom.xml
```

Required fixes:
- Add Java version properties
- Specify Spring Boot version
- Add compiler plugin
- Set test scope for JUnit

Example properties section:
```xml
<properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <spring-boot.version>2.7.0</spring-boot.version>
</properties>
```

Example dependency with version:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <version>${spring-boot.version}</version>
</dependency>
```

Add compiler plugin:
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>3.8.1</version>
    <configuration>
        <source>11</source>
        <target>11</target>
    </configuration>
</plugin>
```

### 2. Create Dockerfile

Create a Dockerfile for the application:
```bash
cat > /root/app-repo/Dockerfile <<'EOF'
FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
```

### 3. Fix Jenkinsfile Build Stage

Edit the Jenkinsfile:
```bash
nano /root/app-repo/Jenkinsfile
```

Fix the build stage:
- Change `mvn clean packages` to `mvn clean package`
- Ensure Docker build command is correct
- Add proper tagging

Corrected build stage:
```groovy
stage('Build') {
    steps {
        sh 'mvn clean package'
        sh "docker build -t ${APP_NAME}:${BUILD_NUMBER} ."
        sh "docker tag ${APP_NAME}:${BUILD_NUMBER} ${APP_NAME}:latest"
    }
}
```

### 4. Fix Environment Variables

Update environment section:
```groovy
environment {
    DOCKER_REGISTRY = 'docker.io/yourusername'  // Use real registry
    DOCKER_CREDENTIALS = 'docker-hub-creds'
    APP_NAME = 'my-app'
    MAVEN_OPTS = '-Xmx1024m'  // Increase memory
}
```

### 5. Create Build Scripts

Create a build script if needed:
```bash
cat > /root/app-repo/build.sh <<'EOF'
#!/bin/bash
mvn clean package
docker build -t my-app:latest .
EOF
chmod +x /root/app-repo/build.sh
```

## Validation

Test Maven build locally:
```bash
cd /root/app-repo
mvn clean package
```

Check if JAR is created:
```bash
ls -la target/*.jar
```

## Checklist

- [ ] Maven pom.xml has Java version specified
- [ ] Spring Boot version defined
- [ ] Compiler plugin added
- [ ] JUnit scope set to test
- [ ] Dockerfile created
- [ ] Jenkinsfile build stage fixed
- [ ] Maven command typo corrected
- [ ] Environment variables updated