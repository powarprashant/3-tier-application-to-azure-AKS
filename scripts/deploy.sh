#!/bin/bash
set -e
 


IMAGE_TAG=$1
 
if [ -z "$IMAGE_TAG" ]; then
  echo " Image tag not provided"
  echo "Usage: bash scripts/deploy.sh <IMAGE_TAG>"
  exit 1
fi
 

NAMESPACE="three-tier"
RELEASE_NAME="database"   
CHART_PATH="./helm/crud-app-chart"
 
BACKEND_REPO=${DOCKER_REPO_BACKEND}
FRONTEND_REPO=${DOCKER_REPO_FRONTEND}
 
echo "Using Docker image tag: $IMAGE_TAG"
 

echo "========================================="
echo "⎈ Creating namespace (if not exists)..."
echo "========================================="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
 

echo "========================================="
echo " Deploying Application (DB + Backend + Frontend)..."
echo "========================================="
 
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" \
  --set backend.image.repository="$BACKEND_REPO" \
  --set backend.image.tag="$IMAGE_TAG" \
  --set frontend.image.repository="$FRONTEND_REPO" \
  --set frontend.image.tag="$IMAGE_TAG"
 

echo " Waiting for pods to stabilize..."
sleep 20
 
echo "========================================="
echo " Checking pod status..."
echo "========================================="
kubectl get pods -n "$NAMESPACE"
 
FAILED=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -E "CrashLoopBackOff|Error|ImagePullBackOff" | wc -l)
 
if [ "$FAILED" -gt 0 ]; then
  echo " Deployment has issues. Please check pod logs."
  exit 1
fi
 
echo "========================================="
echo " Deployment Successful!"
echo "========================================="