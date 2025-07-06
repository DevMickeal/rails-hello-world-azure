#!/bin/bash

# Deploy Rails Hello World to local Kubernetes cluster
set -e

echo "🚀 Deploying Rails Hello World to local Kubernetes cluster..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed. Please install helm first."
    exit 1
fi

# Check if we have a local cluster running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ No Kubernetes cluster found. Please start your local cluster (minikube, kind, etc.)"
    exit 1
fi

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace rails-hello-world --dry-run=client -o yaml | kubectl apply -f -

# Generate a secret key base
SECRET_KEY_BASE=$(openssl rand -hex 64)

# Create values file for local deployment
cat > values-local.yaml << EOF
rails:
  image:
    repository: rails-hello-world
    tag: latest
  env:
    SECRET_KEY_BASE: ${SECRET_KEY_BASE}
    DATABASE_URL: postgresql://postgres:password@postgres-service:5432/rails_app_production
    REDIS_URL: redis://rails-hello-world-redis:6379
  ingress:
    enabled: false
  service:
    type: LoadBalancer

redis:
  enabled: true
  persistence:
    enabled: false

prometheus:
  enabled: true
  persistence:
    enabled: false

grafana:
  enabled: true
  persistence:
    enabled: false
  adminPassword: admin123

global:
  environment: local
EOF

# Build and load Docker image (for minikube)
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "🐳 Building and loading Docker image to minikube..."
    eval $(minikube docker-env)
    docker build -t rails-hello-world:latest .
fi

# Install/upgrade Helm chart
echo "📊 Installing Helm chart..."
helm upgrade --install rails-hello-world ./helm \
  --namespace rails-hello-world \
  --values values-local.yaml \
  --wait \
  --timeout 10m

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/rails-hello-world-rails -n rails-hello-world
kubectl wait --for=condition=available --timeout=300s deployment/rails-hello-world-redis -n rails-hello-world
kubectl wait --for=condition=available --timeout=300s deployment/rails-hello-world-prometheus -n rails-hello-world
kubectl wait --for=condition=available --timeout=300s deployment/rails-hello-world-grafana -n rails-hello-world

# Get service URLs
echo "🔍 Getting service URLs..."

if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    RAILS_URL=$(minikube service rails-hello-world-rails --url -n rails-hello-world)
    GRAFANA_URL=$(minikube service rails-hello-world-grafana --url -n rails-hello-world)
    PROMETHEUS_URL=$(minikube service rails-hello-world-prometheus --url -n rails-hello-world)
else
    echo "📋 Service URLs (use kubectl port-forward to access):"
    echo "  Rails API: kubectl port-forward svc/rails-hello-world-rails 3000:3000 -n rails-hello-world"
    echo "  Grafana: kubectl port-forward svc/rails-hello-world-grafana 3001:3000 -n rails-hello-world"
    echo "  Prometheus: kubectl port-forward svc/rails-hello-world-prometheus 9090:9090 -n rails-hello-world"
fi

# Test the API
echo "🧪 Testing API endpoints..."
sleep 10

if [ ! -z "$RAILS_URL" ]; then
    echo "Testing health endpoint..."
    curl -f "${RAILS_URL}/health"
    echo ""
    
    echo "Testing hello endpoint..."
    curl -f "${RAILS_URL}/hello"
    echo ""
    
    echo "Testing Redis endpoint..."
    curl -f "${RAILS_URL}/redis"
    echo ""
    
    echo "Testing metrics endpoint..."
    curl -f "${RAILS_URL}/metrics"
    echo ""
fi

echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Access URLs:"
if [ ! -z "$RAILS_URL" ]; then
    echo "  Rails API: ${RAILS_URL}"
    echo "  Health: ${RAILS_URL}/health"
    echo "  Hello: ${RAILS_URL}/hello"
    echo "  Redis: ${RAILS_URL}/redis"
    echo "  Metrics: ${RAILS_URL}/metrics"
    echo "  Grafana: ${GRAFANA_URL} (admin/admin123)"
    echo "  Prometheus: ${PROMETHEUS_URL}"
else
    echo "  Use kubectl port-forward to access services:"
    echo "    kubectl port-forward svc/rails-hello-world-rails 3000:3000 -n rails-hello-world"
    echo "    kubectl port-forward svc/rails-hello-world-grafana 3001:3000 -n rails-hello-world"
    echo "    kubectl port-forward svc/rails-hello-world-prometheus 9090:9090 -n rails-hello-world"
fi

echo ""
echo "🔧 Useful commands:"
echo "  View logs: kubectl logs -f deployment/rails-hello-world-rails -n rails-hello-world"
echo "  View pods: kubectl get pods -n rails-hello-world"
echo "  View services: kubectl get svc -n rails-hello-world"
echo "  Delete deployment: helm uninstall rails-hello-world -n rails-hello-world" 