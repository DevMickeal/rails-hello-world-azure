locals {
  environment = "production"
  location    = var.location
  
  common_tags = {
    Environment     = local.environment
    Project         = var.project_name
    ManagedBy       = "Terraform"
    LastUpdated     = timestamp()
    CostCenter      = var.cost_center
    Owner           = var.owner_email
    Compliance      = "PCI-DSS"
    DataClassification = "Confidential"
  }
}


# Create the resource group at the root, and pass its name to all modules
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${local.environment}-rg"
  location = local.location
  tags     = local.common_tags
}

# Key production differences in module calls:

# AKS Module - Production sizing
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
  resource_group_name = azurerm_resource_group.main.name
  kubernetes_version  = "1.28.3"
  os_disk_size_gb = 128
  system_node_count     = 3
  system_node_size      = "Standard_D4s_v5"
  system_node_min_count = 3
  system_node_max_count = 6
  system_node_max_pods  = 30
  user_node_count     = 3
  user_node_size      = "Standard_D8s_v5"
  user_node_min_count = 3
  user_node_max_count = 10
  acr_sku = "Premium"
  common_tags = local.common_tags
}

# Database Module - Production HA
module "database" {
  action_group_id            = module.monitoring.action_group_id
  database_subnet_id = module.networking.database_subnet_id
  postgres_dns_zone_id = module.networking.postgres_dns_zone_id
  postgresql_configurations = {
    "shared_preload_libraries" = "pg_stat_statements"
    "pg_stat_statements.track" = "all"
    "log_statement"            = "all"
    "log_min_duration_statement" = "1000"
  }
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  key_vault_id               = module.security.key_vault_id
  source = "../../modules/database"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  postgresql_version    = "15"
  administrator_login   = "railsadmin"
  sku_name             = "GP_Standard_D2s_v3"
  storage_mb           = 32768
  backup_retention_days = 30
  standby_availability_zone = ""
  common_tags = local.common_tags
}

# Redis Module - Production tier
module "redis" {
  action_group_id            = module.monitoring.action_group_id
  redis_subnet_id   = module.networking.redis_subnet_id
  redis_dns_zone_id = module.networking.redis_dns_zone_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  key_vault_id               = module.security.key_vault_id
  maxmemory_reserved = 10
  maxmemory_delta    = 10
  backup_storage_connection_string = ""
  source = "../../modules/redis"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  capacity = 2
  family   = "P"
  sku_name = "Premium"
  shard_count = 2
  common_tags = local.common_tags
}

# Monitoring - Longer retention
module "monitoring" {
  key_vault_id = module.security.key_vault_id
  source = "../../modules/monitoring"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days = 90
  alert_email       = var.alert_email
  webhook_receivers = []
  common_tags = local.common_tags
}
# Key production differences in module calls:

# Networking Module
module "networking" {
  source = "../../modules/networking"
  project_name        = var.project_name
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.1.0.0/16"]
  aks_subnet_cidr     = "10.1.0.0/20"
  database_subnet_cidr = "10.1.16.0/24"
  redis_subnet_cidr   = "10.1.17.0/24"
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
  aks_cluster_id = module.aks.cluster_id
  common_tags = local.common_tags
}