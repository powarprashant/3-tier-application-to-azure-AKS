#!/bin/bash
set -e
 
IMAGE_TAG=$1
 
echo "Using Docker image tag: $IMAGE_TAG"
 
NAMESPACE="three-tier"
BACKEND_REPO=${DOCKER_REPO_BACKEND}
FRONTEND_REPO=${DOCKER_REPO_FRONTEND}
 
echo "========================================="
echo "⎈ Creating namespace (if not exists)..."
echo "========================================="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
 
echo "========================================="
echo "🚀 Deploying Application (DB + Backend + Frontend)..."
echo "========================================="
 
helm upgrade --install three-tier-app ./helm/crud-app-chart \
  --namespace "$NAMESPACE" \
  --set backend.image.repository="$BACKEND_REPO" \
  --set backend.image.tag="$IMAGE_TAG" \
  --set frontend.image.repository="$FRONTEND_REPO" \
  --set frontend.image.tag="$IMAGE_TAG"
 
echo "========================================="
echo "🔍 Checking pod health..."
echo "========================================="
 
kubectl get pods -n "$NAMESPACE"
 
echo "🎉 Deployment Successful!"