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

# -------------------------------------------------------
# 🚀 Deploy PostgreSQL
# -------------------------------------------------------
echo "========================================="
echo "📦 Deploying PostgreSQL..."
echo "========================================="

helm upgrade --install database ./helm/crud-app-chart \
  --namespace "$NAMESPACE"

echo "⏳ Waiting 30 seconds for PostgreSQL to initialize..."
sleep 30
kubectl get pods -n "$NAMESPACE"

# -------------------------------------------------------
# 🚀 Deploy Backend
# -------------------------------------------------------
echo "========================================="
echo "🟦 Deploying Backend..."
echo "========================================="

helm upgrade --install backend ./helm/backend-chart \
  --namespace "$NAMESPACE" \
  --set image.repository="$BACKEND_REPO" \
  --set image.tag="$IMAGE_TAG"

# -------------------------------------------------------
# 🚀 Deploy Frontend
# -------------------------------------------------------
echo "========================================="
echo "🟩 Deploying Frontend..."
echo "========================================="

helm upgrade --install frontend ./helm/frontend-chart \
  --namespace "$NAMESPACE" \
  --set image.repository="$FRONTEND_REPO" \
  --set image.tag="$IMAGE_TAG"

# -------------------------------------------------------
# 🔍 HEALTH CHECK
# -------------------------------------------------------
echo "========================================="
echo "🔍 Checking pod health..."
echo "========================================="

FAILED=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -E "CrashLoopBackOff|Error" | wc -l)

kubectl get pods -n "$NAMESPACE"

if [ "$FAILED" -gt 0 ]; then
  echo "❌ Deployment failed! Rolling back..."
  helm rollback backend 1 -n "$NAMESPACE" || true
  helm rollback frontend 1 -n "$NAMESPACE" || true
  exit 1
fi

echo "🎉 Deployment Successful!"
