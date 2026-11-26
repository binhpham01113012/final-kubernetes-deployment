#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

PROFILE="final-project"

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-arm64
export PATH="$JAVA_HOME/bin:$PATH"
export MAVEN_OPTS="-Xmx256m"

echo "======================================"
echo "Final Kubernetes Deployment"
echo "======================================"

echo "[1/9] Checking required software..."

for cmd in docker minikube kubectl java; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required software: $cmd"
        exit 1
    fi
    echo "$cmd is available"
done

echo "[2/9] Starting Minikube..."

if [ -f "$HOME/.minikube/profiles/$PROFILE/config.json" ]; then
    minikube start -p "$PROFILE"
else
    minikube start -p "$PROFILE" \
        --driver=docker \
        --cpus=3 \
        --memory=3200
fi

kubectl config use-context "$PROFILE"

echo "[3/9] Checking existing resources..."

kubectl get configmaps
kubectl get deployments
kubectl get services

echo "[4/9] Validating YAML files..."

for file in \
    pv.yaml \
    pvc.yaml \
    mysql-configmap.yaml \
    mysql-deployment.yaml \
    jenkins-deployment.yaml \
    nexus-deployment.yaml \
    webapp-deployment.yaml \
    service.yaml
do
    echo "Checking $file"
    kubectl apply --dry-run=client -f "$file"
done

echo "[5/9] Deploying storage and configuration..."

kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl apply -f mysql-configmap.yaml
kubectl apply -f service.yaml

echo "[6/9] Deploying MySQL..."

kubectl apply -f mysql-deployment.yaml
kubectl scale deployment/mysql --replicas=1
kubectl rollout status deployment/mysql --timeout=600s

echo "[7/9] Building and deploying Spring Boot..."

chmod +x mvnw
./mvnw -B clean package -DskipTests

minikube -p "$PROFILE" image build \
    -t helloworld:1.0 .

kubectl apply -f webapp-deployment.yaml
kubectl rollout restart deployment/webapp
kubectl rollout status deployment/webapp --timeout=600s

echo "[8/9] Deploying Jenkins and Nexus..."

kubectl apply -f jenkins-deployment.yaml
kubectl scale deployment/jenkins --replicas=1
kubectl rollout status deployment/jenkins --timeout=600s

kubectl apply -f nexus-deployment.yaml
kubectl scale deployment/nexus --replicas=1
kubectl rollout status deployment/nexus --timeout=900s

echo "[9/9] Verifying all Kubernetes resources..."

kubectl wait --for=condition=Available \
    deployment/mysql \
    deployment/webapp \
    deployment/jenkins \
    deployment/nexus \
    --timeout=300s

kubectl get nodes
kubectl get configmaps
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get pv
kubectl get pvc
kubectl get endpointslices

echo "======================================"
echo "All Kubernetes deployments successful!"
echo "======================================"
