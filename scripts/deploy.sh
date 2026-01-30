#!/bin/bash
set -e

IMAGE_TAG=$1

echo "Using Docker image tag: $IMAGE_TAG"

NAMESPACE="three-tier"
HELM_CHART="./helm"
BACKEND_REPO="${DOCKER_REPO_BACKEND}"
FRONTEND_REPO="${DOCKER_REPO_FRONTEND}"

echo "========================================="
echo "⎈ Creating namespace (if not exists)..."
echo "========================================="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -


# -------------------------------------------------------
# 🚀 Deploy PostgreSQL (crud-app-chart)
# -------------------------------------------------------
echo "========================================="
echo "📦 Deploying PostgreSQL..."
echo "========================================="

helm upgrade --install database "${HELM_CHART}/crud-app-chart" \
  --namespace "$NAMESPACE"

echo "⏳ Waiting 30 seconds for PostgreSQL to initialize..."
sleep 30

kubectl get pods -n "$NAMESPACE"


# -------------------------------------------------------
# 🚀 Deploy Backend Microservice
# -------------------------------------------------------
echo "========================================="
echo "🟦 Deploying Backend..."
echo "========================================="

helm upgrade --install backend "${HELM_CHART}/backend" \
  --namespace "$NAMESPACE" \
  --set image.repository="$BACKEND_REPO" \
  --set image.tag="$IMAGE_TAG"


# -------------------------------------------------------
# 🚀 Deploy Frontend Microservice
# -------------------------------------------------------
echo "========================================="
echo "🟩 Deploying Frontend..."
echo "========================================="

helm upgrade --install frontend "${HELM_CHART}/frontend" \
  --namespace "$NAMESPACE" \
  --set image.repository="$FRONTEND_REPO" \
  --set image.tag="$IMAGE_TAG"


# -------------------------------------------------------
# 🔍 HEALTH CHECK
# -------------------------------------------------------
echo "========================================="
echo "🔍 Checking Pod Health..."
echo "========================================="

sleep 20
kubectl get pods -n "$NAMESPACE"

FAILED=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -E "CrashLoopBackOff|ImagePullBackOff|Error" | wc -l)

if [ "$FAILED" -gt 0 ]; then
  echo "❌ Deployment Failed — Rolling Back!"
  helm rollback backend 1 -n "$NAMESPACE" || true
  helm rollback frontend 1 -n "$NAMESPACE" || true
  helm rollback database 1 -n "$NAMESPACE" || true
  exit 1
fi

echo "========================================="
echo "🎉 Deployment COMPLETE Successfully!"
echo "========================================="
