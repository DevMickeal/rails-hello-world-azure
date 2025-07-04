# Rails Hello World Application on Azure

## Overview

This repository contains a production-ready Rails "Hello World" application with PostgreSQL and Redis, designed to run on Azure Kubernetes Service (AKS) with comprehensive monitoring and observability.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Resource Group                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐          │
│  │     AKS     │  │ Azure Cache  │  │  Azure DB for │          │
│  │   Cluster   │  │  for Redis   │  │  PostgreSQL   │          │
│  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘          │
│         │                 │                   │                   │
│  ┌──────▼─────────────────▼───────────────────▼──────┐          │
│  │              Kubernetes Namespace                  │          │
│  ├────────────────────────────────────────────────────┤          │
│  │  Rails App │ Prometheus │ Grafana │ AlertManager  │          │
│  └────────────────────────────────────────────────────┘          │
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐          │
│  │ Application │  │ Log Analytics │  │ Azure Monitor │          │
│  │  Insights   │  │  Workspace    │  │               │          │
│  └─────────────┘  └──────────────┘  └───────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Required Tools

- **Azure CLI** (>= 2.50.0)
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```

- **kubectl** (>= 1.28)
  ```bash
  az aks install-cli
  ```

- **Helm** (>= 3.12)
  ```bash
  curl https://get.helm.io/helm-v3.12.0-linux-amd64.tar.gz | tar xz
  sudo mv linux-amd64/helm /usr/local/bin/
  ```

- **Terraform** (>= 1.5)
  ```bash
  wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
  unzip terraform_1.5.0_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
  ```

- **Docker** (>= 24.0)
- **Ruby** (>= 3.2) with Rails (>= 7.1)

### Azure Account Setup

1. Login to Azure:
   ```bash
   az login
   ```

2. Set your subscription:
   ```bash
   az account set --subscription "Your-Subscription-Name"
   ```

3. Create a service principal for automation:
   ```bash
   az ad sp create-for-rbac --name "rails-app-sp" --role contributor \
     --scopes /subscriptions/{subscription-id} \
     --sdk-auth > azure-credentials.json
   ```

## Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/your-org/rails-hello-world-azure.git
cd rails-hello-world-azure

# Run the setup script
./scripts/setup.sh --environment staging --region eastus
```

### Option 2: Manual Setup

Follow the detailed steps below.

## Detailed Setup Instructions

### 1. Rails Application Setup

#### Create the Rails Application

```bash
# Create new Rails app
rails new hello-world-app --database=postgresql --skip-test

cd hello-world-app

# Add required gems to Gemfile
cat >> Gemfile << 'EOF'

# Monitoring and observability
gem 'prometheus-client'
gem 'yabeda-rails'
gem 'yabeda-prometheus'
gem 'yabeda-sidekiq'
gem 'yabeda-puma-plugin'

# Redis
gem 'redis', '~> 5.0'
gem 'hiredis'

# Background jobs
gem 'sidekiq', '~> 7.1'

# Health checks
gem 'health_check'

# Azure specific
gem 'azure-storage-blob'
gem 'applicationinsights'
EOF

# Install dependencies
bundle install
```

#### Configure the Application

1. **Database Configuration** (`config/database.yml`):
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  
production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
  ssl_mode: require
```

2. **Redis Configuration** (`config/initializers/redis.rb`):
```ruby
require 'redis'

redis_config = {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } # For Azure Redis
}

Redis.current = Redis.new(redis_config)
```

3. **Prometheus Metrics** (`config/initializers/prometheus.rb`):
```ruby
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'yabeda/prometheus'

Yabeda.configure do
  # Custom metrics
  counter :http_requests_total, 
          comment: "Total HTTP requests",
          tags: [:controller, :action, :status]
  
  histogram :http_request_duration, 
            comment: "HTTP request duration",
            unit: :seconds,
            tags: [:controller, :action]
  
  gauge :active_connections,
        comment: "Number of active database connections"
end

# Start Prometheus exporter on port 9394
Yabeda::Prometheus::Exporter.start_metrics_server!
```

4. **Health Check Endpoint** (`config/routes.rb`):
```ruby
Rails.application.routes.draw do
  health_check_routes
  
  root 'welcome#index'
  get 'hello', to: 'welcome#hello'
end
```

5. **Create Welcome Controller**:
```bash
rails generate controller Welcome index hello
```

Update `app/controllers/welcome_controller.rb`:
```ruby
class WelcomeController < ApplicationController
  def index
    render json: { message: "Hello World from Rails on Azure!" }
  end
  
  def hello
    # Test database connection
    db_version = ActiveRecord::Base.connection.select_value('SELECT version()')
    
    # Test Redis connection
    redis_ping = Redis.current.ping
    
    render json: {
      message: "Hello World!",
      rails_version: Rails.version,
      database: {
        connected: true,
        version: db_version
      },
      redis: {
        connected: redis_ping == "PONG"
      },
      timestamp: Time.current
    }
  end
end
```

#### Dockerize the Application

Create `Dockerfile`:
```dockerfile
FROM ruby:3.2-alpine AS builder

RUN apk add --update --no-cache \
    build-base \
    postgresql-dev \
    git \
    nodejs \
    yarn \
    tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

COPY . .

RUN bundle exec rails assets:precompile

# Runtime stage
FROM ruby:3.2-alpine

RUN apk add --update --no-cache \
    postgresql-client \
    tzdata \
    nodejs \
    curl

WORKDIR /app

COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle

EXPOSE 3000 9394

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```


### 2. Azure Infrastructure Setup

#### Terraform Infrastructure

This repository provides a complete, production-ready Terraform setup for deploying a Rails application and its dependencies (AKS, PostgreSQL, Redis, monitoring, security, and networking) on Azure.

**Key Features:**
- Multi-environment support: dev, staging, prod
- Modular structure: each major resource is a separate module
- Remote backend (Azure Storage Account) for state management
- CI/CD ready: GitHub Actions workflows for automated deployment
- Secure: No secrets are committed; all credentials are handled via environment variables or GitHub secrets

#### How to Use

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/rails-hello-world-azure.git
   cd rails-hello-world-azure
   ```

2. **Configure Azure credentials**
   - For CI/CD: Add `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` as GitHub repository secrets.
   - For local use: Authenticate with `az login` or set the following environment variables:
     ```bash
     export ARM_CLIENT_ID=...
     export ARM_CLIENT_SECRET=...
     export ARM_TENANT_ID=...
     export ARM_SUBSCRIPTION_ID=...
     ```

3. **Remote Backend**
   - The backend is configured to use a single Azure Storage Account for all environments. The storage account and container can be bootstrapped using the provided script: `terraform/scripts/bootstrap-remote-backend.sh`.

4. **Environments**
   - Each environment (dev, staging, prod) has its own directory under `terraform/environment/`.
   - All variables are managed via `terraform.tfvars` files in each environment directory.

5. **CI/CD Pipeline**
   - The repository includes a reusable GitHub Actions pipeline template and a multi-stage workflow (`deploy-all-env.yml`) that deploys dev, staging, and prod in order.
   - Staging and production deployments require manual approval via GitHub Environments.

6. **Manual Usage**
   - To deploy manually:
     ```bash
     cd terraform/environment/dev   # or staging/prod
     terraform init
     terraform plan -out=tfplan
     terraform apply tfplan
     ```

7. **Cleanup**
   - To destroy all resources:
     ```bash
     cd terraform/environment/dev   # or staging/prod
     terraform destroy -auto-approve
     ```

#### Additional Notes

- All secrets and sensitive values must be managed via Azure Key Vault or GitHub secrets.
- The infrastructure is designed for extensibility and production-readiness, but you can easily scale it down for test/dev use.
- For troubleshooting, see Azure Monitor, Application Insights, and the outputs of your GitHub Actions runs.

---

For any issues, please open an issue or discussion in this repository.

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Get AKS credentials
az aks get-credentials --resource-group rails-app-staging-rg --name rails-app-staging-aks

# Get ACR credentials
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
az acr login --name $ACR_LOGIN_SERVER
```

### 4. Build and Push Docker Image

```bash
# Build Rails application image
docker build -t rails-hello-world:latest .

# Tag for ACR
docker tag rails-hello-world:latest $ACR_LOGIN_SERVER/rails-hello-world:latest

# Push to ACR
docker push $ACR_LOGIN_SERVER/rails-hello-world:latest
```

### 5. Deploy to Kubernetes

#### Create Kubernetes Manifests

Create `k8s/base/namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: rails-app
```

Create `k8s/base/configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: rails-app-config
  namespace: rails-app
data:
  RAILS_ENV: "production"
  RAILS_LOG_TO_STDOUT: "true"
  RAILS_SERVE_STATIC_FILES: "true"
  PROMETHEUS_EXPORTER_PORT: "9394"
```

Create `k8s/base/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rails-app
  namespace: rails-app
  labels:
    app: rails-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rails-app
  template:
    metadata:
      labels:
        app: rails-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9394"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: rails
        image: ${ACR_LOGIN_SERVER}/rails-hello-world:latest
        ports:
        - containerPort: 3000
          name: http
        - containerPort: 9394
          name: metrics
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: rails-app-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: rails-app-secrets
              key: redis-url
        - name: APPLICATIONINSIGHTS_CONNECTION_STRING
          valueFrom:
            secretKeyRef:
              name: rails-app-secrets
              key: appinsights-connection-string
        envFrom:
        - configMapRef:
            name: rails-app-config
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health/database
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
```

Create `k8s/base/service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: rails-app
  namespace: rails-app
  labels:
    app: rails-app
spec:
  selector:
    app: rails-app
  ports:
  - name: http
    port: 80
    targetPort: 3000
  - name: metrics
    port: 9394
    targetPort: 9394
  type: ClusterIP
```

Create `k8s/base/ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rails-app
  namespace: rails-app
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - rails-hello-world.example.com
    secretName: rails-app-tls
  rules:
  - host: rails-hello-world.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: rails-app
            port:
              number: 80
```

#### Deploy Application

```bash
# Create secrets
kubectl create namespace rails-app

kubectl create secret generic rails-app-secrets \
  --namespace rails-app \
  --from-literal=database-url="$(terraform output -raw database_connection_string)" \
  --from-literal=redis-url="$(terraform output -raw redis_connection_string)" \
  --from-literal=appinsights-connection-string="InstrumentationKey=$(terraform output -raw application_insights_key)"

# Apply Kubernetes manifests
kubectl apply -f k8s/base/

# Verify deployment
kubectl get pods -n rails-app
kubectl logs -n rails-app -l app=rails-app
```

### 6. Setup Monitoring Stack

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123 \
  --wait

# Create ServiceMonitor for Rails app
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: rails-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: rails-app
  namespaceSelector:
    matchNames:
    - rails-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
EOF
```

## Verification

### 1. Check Application Health

```bash
# Get the external IP
kubectl get ingress -n rails-app

# Test the application
curl http://<EXTERNAL_IP>/hello

# Expected response:
# {
#   "message": "Hello World!",
#   "rails_version": "7.1.0",
#   "database": {
#     "connected": true,
#     "version": "PostgreSQL 15.x"
#   },
#   "redis": {
#     "connected": true
#   },
#   "timestamp": "2024-01-15T10:00:00Z"
# }
```

### 2. Access Monitoring

```bash
# Port-forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access Grafana at http://localhost:3000
# Username: admin
# Password: admin123
```

### 3. View Metrics

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access Prometheus at http://localhost:9090
# Query examples:
# - rate(http_requests_total[5m])
# - histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

## Monitoring Configuration

### Key Metrics to Monitor

#### Rails Application
- `http_requests_total` - Request rate by status code
- `http_request_duration_seconds` - Request latency percentiles
- `rails_db_runtime_seconds` - Database query performance
- `puma_workers` - Web server worker count
- `puma_running_threads` - Active thread count
- `active_record_connection_pool_size` - DB connection pool metrics

#### PostgreSQL (via Azure Monitor)
- Connection count
- CPU and memory utilization
- Storage usage
- Replication lag
- Query performance insights

#### Redis (via Azure Monitor)
- Connected clients
- Memory usage
- Cache hit ratio
- Operations per second
- Evicted keys

### Alert Rules

See `monitoring/alerting-rules.yaml` for production-ready alert configurations.

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check database firewall rules
   az postgres flexible-server firewall-rule create \
     --resource-group rails-app-staging-rg \
     --name rails-app-staging-psql \
     --rule-name allow-aks \
     --start-ip-address 0.0.0.0 \
     --end-ip-address 255.255.255.255
   ```

2. **Redis Connection Issues**
   ```bash
   # Verify Redis is accessible
   kubectl run redis-cli --rm -it --image=redis -- redis-cli -h <redis-host> -a <redis-password> ping
   ```

3. **Image Pull Errors**
   ```bash
   # Attach ACR to AKS
   az aks update -n rails-app-staging-aks -g rails-app-staging-rg \
     --attach-acr $(az acr show --name railsappstagingacr --query id -o tsv)
   ```

## Production Considerations

1. **Security**
   - Enable Azure Key Vault for secret management
   - Implement Pod Security Policies
   - Use Azure AD for RBAC
   - Enable network policies

2. **High Availability**
   - Configure Pod Disruption Budgets
   - Implement proper health checks
   - Use Azure Traffic Manager for multi-region

3. **Backup and Disaster Recovery**
   - Enable automated PostgreSQL backups
   - Configure Redis persistence
   - Implement GitOps for configuration management

4. **Performance**
   - Enable autoscaling (HPA and VPA)
   - Configure resource limits appropriately
   - Use Azure CDN for static assets

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy -auto-approve

# Remove Kubernetes resources
kubectl delete namespace rails-app
kubectl delete namespace monitoring
```

## Support

For issues or questions:
- Check Azure Monitor for infrastructure metrics
- Review Application Insights for application telemetry
- Check Grafana dashboards for detailed metrics
- Review pod logs: `kubectl logs -n rails-app -l app=rails-app`

## License

MIT License - see LICENSE file for details