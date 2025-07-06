# Rails Hello World API with Azure Kubernetes Service (AKS)

A complete "Hello World" Rails API application deployed on Azure Kubernetes Service (AKS) with PostgreSQL, Redis, Prometheus, and Grafana monitoring.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Development   │    │    Staging      │    │   Production    │
│   Environment   │    │   Environment   │    │   Environment   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Kubernetes Service                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ Rails API   │  │   Redis     │  │ Prometheus  │            │
│  │ (2 replicas)│  │ (1 replica) │  │ (1 replica) │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ Grafana     │  │ PostgreSQL  │  │ Ingress     │            │
│  │ (1 replica) │  │ (Azure DB)  │  │ Controller  │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Features

- **Rails API**: API-only Rails application with health, hello, Redis test, and metrics endpoints
- **Multi-Environment**: Development, Staging, and Production environments
- **Infrastructure as Code**: Terraform modules for Azure resources
- **Container Orchestration**: Kubernetes deployment with Helm charts
- **Monitoring**: Prometheus for metrics collection and Grafana for visualization
- **CI/CD**: GitHub Actions pipeline with reusable workflows
- **Database**: Azure Database for PostgreSQL
- **Caching**: Redis for session storage and caching
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA) for production

## 📁 Project Structure

```
rails-hello-world-azure/
├── .github/
│   └── workflows/
│       ├── deploy-all-env.yml          # Main deployment pipeline
│       └── templates/
│           ├── deploy-infrastructure.yml # Infrastructure deployment template
│           └── deploy-app.yml          # Application deployment template
├── helm/
│   ├── Chart.yaml                      # Helm chart metadata
│   ├── values.yaml                     # Base values
│   ├── values-dev.yaml                 # Development environment values
│   ├── values-staging.yaml             # Staging environment values
│   ├── values-production.yaml          # Production environment values
│   └── templates/
│       ├── _helpers.tpl                # Helm helper functions
│       ├── rails-deployment.yaml       # Rails API deployment
│       ├── rails-service.yaml          # Rails API service
│       ├── redis-deployment.yaml       # Redis deployment
│       ├── redis-service.yaml          # Redis service
│       ├── prometheus-deployment.yaml  # Prometheus deployment
│       ├── prometheus-service.yaml     # Prometheus service
│       ├── grafana-deployment.yaml     # Grafana deployment
│       ├── grafana-service.yaml        # Grafana service
│       ├── serviceaccount.yaml         # Service account
│       ├── secrets.yaml                # Kubernetes secrets
│       └── rails-hpa.yaml              # Horizontal Pod Autoscaler
├── terraform/
│   ├── environment/
│   │   ├── dev/                        # Development infrastructure
│   │   ├── staging/                    # Staging infrastructure
│   │   └── prod/                       # Production infrastructure
│   └── modules/
│       ├── aks/                        # AKS cluster module
│       ├── database/                   # PostgreSQL module
│       ├── monitoring/                 # Monitoring module
│       ├── networking/                 # Networking module
│       ├── redis/                      # Redis module
│       └── security/                   # Security module
├── app/
│   └── controllers/
│       └── hello_controller.rb         # API endpoints
├── config/
│   └── routes.rb                       # API routes
├── scripts/
│   └── deploy-local.sh                 # Local deployment script
├── Dockerfile                          # Rails application container
├── docker-compose.yml                  # Local development setup
└── README.md                           # This file
```

## 🛠️ Prerequisites

- Azure CLI
- kubectl
- Helm
- Docker
- Ruby 3.4+
- Terraform

## 🚀 Quick Start

### 1. Local Development

```bash
# Clone the repository
git clone <repository-url>
cd rails-hello-world-azure

# Start local services
docker-compose up -d

# Install dependencies
bundle install

# Setup database
SECRET_KEY_BASE=$(bin/rails secret) bin/rails db:create
SECRET_KEY_BASE=$(bin/rails secret) bin/rails db:migrate

# Start Rails server
SECRET_KEY_BASE=$(bin/rails secret) bin/rails server

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3000/hello
curl http://localhost:3000/redis
curl http://localhost:3000/metrics
```

### 2. Local Kubernetes Deployment

```bash
# Start local Kubernetes cluster (minikube/kind)
minikube start

# Deploy to local cluster
./scripts/deploy-local.sh
```

### 3. Azure Deployment

#### Setup Azure Credentials

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "rails-hello-world-sp" --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

#### Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```
AZURE_CREDENTIALS: <service-principal-json>
RAILS_SECRET_KEY_BASE: <rails-secret-key>
TF_STATE_RESOURCE_GROUP: <terraform-state-rg>
TF_STATE_STORAGE_ACCOUNT: <terraform-state-storage>
AKS_DEV_RESOURCE_GROUP: <dev-aks-rg>
AKS_DEV_CLUSTER_NAME: <dev-aks-cluster>
AKS_STAGING_RESOURCE_GROUP: <staging-aks-rg>
AKS_STAGING_CLUSTER_NAME: <staging-aks-cluster>
AKS_PROD_RESOURCE_GROUP: <prod-aks-rg>
AKS_PROD_CLUSTER_NAME: <prod-aks-cluster>
DEV_DATABASE_URL: <dev-postgres-connection-string>
STAGING_DATABASE_URL: <staging-postgres-connection-string>
PROD_DATABASE_URL: <prod-postgres-connection-string>
```

#### Deploy Infrastructure

```bash
# Deploy infrastructure to all environments
cd terraform/environment/dev
terraform init
terraform plan
terraform apply

# Repeat for staging and prod environments
```

#### Deploy Application

The application will be automatically deployed via GitHub Actions when you push to the main branch, or you can manually trigger the workflow.

## 📊 API Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/health` | GET | Health check | `{"status": "healthy", "timestamp": "..."}` |
| `/hello` | GET | Hello World | `{"message": "Hello, World!", "timestamp": "..."}` |
| `/redis` | GET | Redis connectivity test | `{"status": "redis_connected", "test_value": "..."}` |
| `/metrics` | GET | Prometheus metrics | Prometheus format metrics |

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RAILS_ENV` | Rails environment | `development` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:password@localhost:5432/rails_app_development` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379` |
| `SECRET_KEY_BASE` | Rails secret key base | Generated automatically |

### Helm Values

The application uses environment-specific Helm values files:

- `helm/values.yaml` - Base configuration
- `helm/values-dev.yaml` - Development environment
- `helm/values-staging.yaml` - Staging environment
- `helm/values-production.yaml` - Production environment

## 📈 Monitoring

### Prometheus Metrics

The application exposes the following metrics:

- `http_requests_total` - Total HTTP requests by endpoint
- `http_request_duration_seconds` - Request duration histogram
- `rails_app_info` - Application information
- `rails_database_connected` - Database connection status
- `rails_redis_connected` - Redis connection status

### Grafana Dashboards

Access Grafana at:
- Development: `https://dev.rails-hello-world.your-domain.com/grafana`
- Staging: `https://staging.rails-hello-world.your-domain.com/grafana`
- Production: `https://rails-hello-world.your-domain.com/grafana`

Default credentials: `admin/admin123`

## 🔄 CI/CD Pipeline

The deployment pipeline follows this flow:

1. **Test & Build**: Run tests, security checks, and build Docker image
2. **Infrastructure Deployment**: Deploy Azure infrastructure using Terraform
3. **Application Deployment**: Deploy Rails application using Helm
4. **Verification**: Test endpoints and verify deployment

### Pipeline Jobs

- `test-and-build`: Test application and build Docker image
- `deploy-infra-{env}`: Deploy infrastructure to specific environment
- `deploy-app-{env}`: Deploy application to specific environment
- `notify-deployment`: Send deployment summary

## 🏗️ Infrastructure

### Azure Resources

- **AKS Clusters**: One per environment (dev, staging, prod)
- **Azure Database for PostgreSQL**: Managed PostgreSQL instances
- **Azure Container Registry**: Docker image storage
- **Azure Storage**: Terraform state storage
- **Azure Key Vault**: Secret management
- **Azure Load Balancer**: Traffic distribution

### Kubernetes Resources

- **Deployments**: Rails API, Redis, Prometheus, Grafana
- **Services**: ClusterIP and LoadBalancer services
- **Ingress**: Nginx ingress controller with TLS
- **HPA**: Horizontal Pod Autoscaler for production
- **Secrets**: Application secrets and database credentials

## 🔒 Security

- TLS encryption for all external traffic
- Azure Key Vault for secret management
- Network policies for pod-to-pod communication
- RBAC for Kubernetes access control
- Container security scanning in CI/CD

## 📝 Development

### Adding New Endpoints

1. Add controller action in `app/controllers/hello_controller.rb`
2. Add route in `config/routes.rb`
3. Update tests
4. Deploy via CI/CD

### Updating Helm Charts

1. Modify values files in `helm/` directory
2. Update templates if needed
3. Test locally with `helm template`
4. Deploy via CI/CD

### Updating Infrastructure

1. Modify Terraform modules in `terraform/modules/`
2. Update environment configurations
3. Test with `terraform plan`
4. Deploy via CI/CD

## 🐛 Troubleshooting

### Common Issues

1. **Redis Connection Failed**
   - Check Redis service is running
   - Verify Redis URL configuration
   - Check network policies

2. **Database Connection Failed**
   - Verify PostgreSQL is accessible
   - Check database URL format
   - Ensure firewall rules allow access

3. **Helm Deployment Failed**
   - Check Helm chart syntax
   - Verify values file format
   - Check Kubernetes cluster access

### Useful Commands

```bash
# Check pod status
kubectl get pods -n rails-hello-world-{env}

# View logs
kubectl logs -f deployment/rails-hello-world-{env}-rails -n rails-hello-world-{env}

# Port forward to access services
kubectl port-forward svc/rails-hello-world-{env}-rails 3000:3000 -n rails-hello-world-{env}

# Check Helm releases
helm list -n rails-hello-world-{env}

# Test endpoints
curl http://localhost:3000/health
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📞 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section
- Review the documentation
