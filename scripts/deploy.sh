#!/bin/bash
set -e

IMAGE_TAG=$1

echo "Using Docker image tag: $IMAGE_TAG"

NAMESPACE="three-tier"
HELM_CHART="./helm"
BACKEND_REPO=${DOCKER_REPO_BACKEND}
FRONTEND_REPO=${DOCKER_REPO_FRONTEND}

echo "Creating namespace if not exists..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying PostgreSQL..."
helm upgrade --install database $HELM_CHART/database \
  --namespace $NAMESPACE

echo "Deploying Backend..."
helm upgrade --install backend $HELM_CHART/backend \
  --namespace $NAMESPACE \
  --set image.repository=$BACKEND_REPO \
  --set image.tag=$IMAGE_TAG

echo "Deploying Frontend..."
helm upgrade --install frontend $HELM_CHART/frontend \
  --namespace $NAMESPACE \
  --set image.repository=$FRONTEND_REPO \
  --set image.tag=$IMAGE_TAG

echo "Waiting for pods to become ready..."
sleep 20
kubectl get pods -n $NAMESPACE

# HEALTH CHECK
FAILED=$(kubectl get pods -n $NAMESPACE --no-headers | grep -E "CrashLoopBackOff|Error" | wc -l)

if [ "$FAILED" -gt 0 ]; then
  echo "❌ Deployment failed! Rolling back..."
  helm rollback backend 1 -n $NAMESPACE || true
  helm rollback frontend 1 -n $NAMESPACE || true
  exit 1
fi

echo "🎉 Deployment Successful!"
