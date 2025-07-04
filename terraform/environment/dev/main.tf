locals {
  environment = "dev"
  location    = var.location
  
  common_tags = {
    Environment     = local.environment
    Project         = var.project_name
    ManagedBy       = "Terraform"
    LastUpdated     = timestamp()
    CostCenter      = var.cost_center
    Owner           = var.owner_email
  }
}

# Create the resource group at the root, and pass its name to all modules
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${local.environment}-rg"
  location = local.location
  tags     = local.common_tags
}

# AKS Module - development sizing
module "aks" {
  aks_subnet_id              = module.networking.aks_subnet_id
  appgw_subnet_id            = module.networking.appgw_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  key_vault_id               = module.security.key_vault_id
  admin_group_object_ids     = var.aks_admin_group_ids
  source = "../../modules/aks"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  os_disk_size_gb = 64
  resource_group_name = azurerm_resource_group.main.name
  kubernetes_version  = "1.28.3"
  system_node_count     = 1
  system_node_size      = "Standard_B2s"
  system_node_min_count = 1
  system_node_max_count = 2
  system_node_max_pods  = 3
  user_node_count       = 0
  user_node_size        = "Standard_B2s"
  user_node_min_count   = 0
  user_node_max_count   = 0
  acr_sku = "Basic"
  common_tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  key_vault_id = module.security.key_vault_id
  source = "../../modules/monitoring"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days = 30
  alert_email       = var.alert_email
  webhook_receivers = []
  common_tags = local.common_tags
}

# Networking Module (simplified)
module "networking" {
  source = "../../modules/networking"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.1.0.0/16"]
  aks_subnet_cidr     = "10.1.0.0/20"
  appgw_subnet_cidr   = "10.1.18.0/24"
  common_tags = local.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  allowed_ips = var.allowed_ips
  allowed_subnet_ids = [
    module.networking.aks_subnet_id,
    module.networking.appgw_subnet_id
  ]
  aks_cluster_id = ""
  common_tags = local.common_tags
}