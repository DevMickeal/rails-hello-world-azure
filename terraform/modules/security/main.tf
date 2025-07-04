# Key Vault and Security configuration

data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "${var.project_name}-${var.environment}-kv"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = var.environment == "production" ? true : false
  sku_name                    = "standard"

  enable_rbac_authorization = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    
    ip_rules = var.allowed_ips
    
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.common_tags
}

# Grant current user/service principal access to Key Vault
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# User Assigned Managed Identity for workloads
resource "azurerm_user_assigned_identity" "workload" {
  name                = "${var.project_name}-${var.environment}-workload-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.common_tags
}

# Grant workload identity access to Key Vault
resource "azurerm_role_assignment" "workload_kv_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

# Azure Policy Assignment for AKS
resource "azurerm_resource_policy_assignment" "aks_baseline" {
  name                 = "${var.project_name}-${var.environment}-aks-baseline"
  resource_id          = var.aks_cluster_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"

  parameters = jsonencode({
    effect = {
      value = var.environment == "production" ? "Deny" : "Audit"
    }
  })
}

# Network Watcher
resource "azurerm_network_watcher" "main" {
  name                = "${var.project_name}-${var.environment}-nw"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.common_tags
}

# DDoS Protection Plan (Production only)
resource "azurerm_network_ddos_protection_plan" "main" {
  count               = var.environment == "production" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-ddos"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.common_tags
}