# Final Kubernetes Deployment

## Project Overview

This project demonstrates a complete DevOps environment
using Kubernetes and Minikube.

The project includes a Spring Boot Hello World application
connected to a MySQL database, Jenkins for automated builds,
and Nexus Repository Manager for artifact storage.

## GitHub Repository

https://github.com/binhpham01113012/final-kubernetes-deployment

## Required Software

- Ubuntu Linux
- Docker
- Minikube
- kubectl
- Git
- OpenJDK 21
- Maven Wrapper

## Environment

- Host: MacBook Pro Apple M2
- Virtualization: UTM
- Virtual Machine: Ubuntu ARM64
- VM CPU: 4 cores
- Minikube Profile: final-project
- Minikube Driver: Docker
- Target Minikube Memory: 3200 MB
- Target Minikube CPU: 3 cores

## Container Images

| Application | Image |
|---|---|
| Jenkins | jenkins/jenkins:lts-jdk21 |
| Nexus | sonatype/nexus3:3.94.4 |
| MySQL | mysql:8.4 |
| Java Runtime | eclipse-temurin:21-jre |
| Webapp | helloworld:1.0 |

## Project Files

- jenkins-deployment.yaml
- nexus-deployment.yaml
- mysql-deployment.yaml
- mysql-configmap.yaml
- webapp-deployment.yaml
- pv.yaml
- pvc.yaml
- service.yaml
- Jenkinsfile
- Dockerfile
- deploy.sh
- pom.xml
- mvnw
- src/

## Java Configuration

The project requires Java 21.

On my Ubuntu ARM64 virtual machine:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-arm64
export PATH="$JAVA_HOME/bin:$PATH"
./mvnw -version
```

On another computer, adjust the JAVA_HOME path in deploy.sh
to match the installed JDK 21 directory.

## Automatic Deployment

```bash
chmod +x mvnw deploy.sh
bash -n deploy.sh
./deploy.sh
```

The deployment script checks the required software, starts
Minikube, validates the YAML files, deploys the application
components, builds the Spring Boot container image, and
verifies the Kubernetes resources.

## Manual Deployment

### Start Minikube

```bash
minikube start -p final-project --driver=docker \
    --cpus=3 --memory=3200

kubectl config use-context final-project
kubectl get nodes
```

For an existing profile, use:

```bash
minikube start -p final-project
```

### Task 1 - Jenkins Deployment

```bash
kubectl apply -f jenkins-deployment.yaml
kubectl rollout status deployment/jenkins --timeout=600s
kubectl get deployment jenkins
kubectl get pods -l app=jenkins
kubectl get pvc jenkins-pvc
```

### Task 2 - Nexus Deployment

```bash
kubectl apply -f nexus-deployment.yaml
kubectl rollout status deployment/nexus --timeout=900s
kubectl get deployment nexus
kubectl get pods -l app=nexus
kubectl get pvc nexus-pvc
```

### Task 3 - MySQL Deployment

Apply the PV, PVC, and ConfigMap before deploying MySQL.

```bash
kubectl apply -f mysql-deployment.yaml
kubectl rollout status deployment/mysql --timeout=600s
kubectl get deployment mysql
kubectl get pods -l app=mysql
```

### Task 4 - MySQL ConfigMap

```bash
kubectl apply -f mysql-configmap.yaml
kubectl get configmap
kubectl describe configmap mysql-config
```

The ConfigMap contains demonstration database credentials
for this academic project. Production passwords should
be stored in Kubernetes Secrets.

### Task 5 - Jenkins Pipeline

1. Complete the initial Jenkins and Nexus setup.
2. Verify that the Nexus maven-snapshots repository exists.
3. Create Jenkins credentials with the ID nexus-credentials.
4. Create a Pipeline job named final-kubernetes-pipeline.
5. Select Pipeline script from SCM.
6. Select Git and enter the public GitHub repository URL.
7. Set the branch to */main.
8. Set the script path to Jenkinsfile.
9. Click Build Now.

The pipeline contains five stages:

- Checkout
- Test
- Build JAR
- Archive Artifact
- Publish to Nexus

Nexus internal repository URL:

http://nexus:8081/repository/maven-snapshots/

Generated JAR:

helloworld-0.0.1-SNAPSHOT.jar

### Task 6 - Webapp Deployment

Build the Spring Boot application and container image:

```bash
./mvnw clean package -DskipTests

minikube -p final-project image build \
    -t helloworld:1.0 .

minikube -p final-project image ls | grep helloworld
```

Deploy the application:

```bash
kubectl apply -f webapp-deployment.yaml
kubectl rollout status deployment/webapp --timeout=600s
kubectl get deployment webapp
kubectl get pods -l app=webapp
kubectl logs deployment/webapp --tail=30
```

### Task 7 - Persistent Volume

```bash
kubectl apply -f pv.yaml
kubectl get pv
kubectl describe pv mysql-pv
```

### Task 8 - Persistent Volume Claim

```bash
kubectl apply -f pvc.yaml
kubectl get pvc
kubectl get pv
```

### Task 9 - Kubernetes Services

```bash
kubectl apply -f service.yaml
kubectl get svc
kubectl get endpointslices
```

### Task 10 - Automatic Deployment Script

```bash
chmod +x deploy.sh
bash -n deploy.sh
./deploy.sh
```

Expected final message:

All Kubernetes deployments successful!

## Accessing Applications

Run each port-forwarding command in a separate terminal.

### Jenkins

```bash
kubectl port-forward service/jenkins 8090:8080
```

URL: http://localhost:8090/

### Nexus

```bash
kubectl port-forward service/nexus 8091:8081
```

URL: http://localhost:8091/

### Spring Boot

```bash
kubectl port-forward service/webapp 8092:8080
```

URL: http://localhost:8092/

## Application Testing

```bash
curl http://localhost:8092/
curl http://localhost:8092/db
curl http://localhost:8092/actuator/health

curl -X POST http://localhost:8092/messages \
    -d "content=Final Kubernetes project"

curl http://localhost:8092/messages
```

Verify the records directly in MySQL:

```bash
kubectl exec deployment/mysql -- sh -c \
'MYSQL_PWD="$MYSQL_PASSWORD" mysql --protocol=TCP \
-h 127.0.0.1 -u "$MYSQL_USER" "$MYSQL_DATABASE" \
-e "SELECT * FROM messages;"'
```

## Persistent Storage

- mysql-pvc: 2Gi
- jenkins-pvc: 5Gi
- nexus-pvc: 5Gi

Persistent storage preserves database records,
Jenkins configuration, and Nexus artifacts.

## Final Verification

```bash
kubectl get nodes
kubectl get deployments
kubectl get pods
kubectl get configmaps
kubectl get svc
kubectl get pv
kubectl get pvc
kubectl get endpointslices
```

All four application deployments should have one ready
replica, and all three PVCs should be Bound.

## Initial Application Configuration

A new deployment requires manual setup of Jenkins and
Nexus administrator accounts, Jenkins plugins, Nexus
credentials, and the Jenkins Pipeline job.

Existing settings are preserved in persistent storage.

## Stop the Environment

Stop port forwarding with Ctrl+C.

```bash
minikube stop -p final-project
```

Do not delete the cluster or persistent storage if the
project environment needs to be preserved.
