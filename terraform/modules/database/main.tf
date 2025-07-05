# PostgreSQL Flexible Server configuration

# Random password generation
resource "random_password" "postgres_admin" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# PostgreSQL Flexible Server (uses delegated subnet directly)
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-psql"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgresql_version
  administrator_login    = var.administrator_login
  administrator_password = random_password.postgres_admin.result
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  
  # Conditional backup retention - only for production
  backup_retention_days  = var.environment == "production" ? 30 : 7

  delegated_subnet_id = var.database_subnet_id
  private_dns_zone_id = var.postgres_dns_zone_id
  public_network_access_enabled = false

  # High availability only for production
  dynamic "high_availability" {
    for_each = var.environment == "production" ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = var.common_tags
}

# Databases
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "${var.project_name}_${var.environment}"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# PostgreSQL Configuration
resource "azurerm_postgresql_flexible_server_configuration" "config" {
  for_each = var.postgresql_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}

# Firewall Rules - Allow Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Store credentials in Key Vault
resource "azurerm_key_vault_secret" "postgres_connection_string" {
  name         = "${var.project_name}-${var.environment}-postgres-connection"
  value        = "postgresql://${var.administrator_login}:${random_password.postgres_admin.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  key_vault_id = var.key_vault_id

  tags = var.common_tags
}

# CHANGED: Diagnostic Settings - Only for production
resource "azurerm_monitor_diagnostic_setting" "postgres" {
  count                      = var.environment == "production" ? 1 : 0
  name                       = "${var.project_name}-${var.environment}-postgres-diag"
  target_resource_id         = azurerm_postgresql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# CHANGED: Alerts - Only for production
resource "azurerm_monitor_metric_alert" "postgres_cpu" {
  count               = var.environment == "production" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-postgres-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  description         = "Alert when PostgreSQL CPU usage is high"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "postgres_storage" {
  count               = var.environment == "production" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-postgres-storage"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  description         = "Alert when PostgreSQL storage usage is high"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.common_tags
}