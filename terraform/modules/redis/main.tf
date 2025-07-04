# Azure Cache for Redis configuration

resource "azurerm_redis_cache" "main" {
  name                = "${var.project_name}-${var.environment}-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku_name
  
  minimum_tls_version = "1.2"

  redis_configuration {
    maxmemory_reserved            = var.maxmemory_reserved
    maxmemory_delta               = var.maxmemory_delta
    maxmemory_policy              = "volatile-lru"
    notify_keyspace_events        = ""
    rdb_backup_enabled            = var.environment == "production" ? true : false
    rdb_backup_frequency          = var.environment == "production" ? 60 : null
    rdb_backup_max_snapshot_count = var.environment == "production" ? 1 : null
    rdb_storage_connection_string = var.environment == "production" ? var.backup_storage_connection_string : null
  }

  patch_schedule {
    day_of_week    = "Sunday"
    start_hour_utc = 23
  }

  tags = var.common_tags
}

# Private Endpoint for Redis
resource "azurerm_private_endpoint" "redis" {
  name                = "${var.project_name}-${var.environment}-redis-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.redis_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-${var.environment}-redis-psc"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis-dns-zone-group"
    private_dns_zone_ids = [var.redis_dns_zone_id]
  }

  tags = var.common_tags
}

# Store Redis connection string in Key Vault
resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "${var.project_name}-${var.environment}-redis-connection"
  value        = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:6380/0"
  key_vault_id = var.key_vault_id

  tags = var.common_tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "redis" {
  name                       = "${var.project_name}-${var.environment}-redis-diag"
  target_resource_id         = azurerm_redis_cache.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ConnectedClientList"
  }
}

# Alerts
resource "azurerm_monitor_metric_alert" "redis_memory" {
  name                = "${var.project_name}-${var.environment}-redis-memory"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_redis_cache.main.id]
  description         = "Alert when Redis memory usage is high"

  criteria {
    metric_namespace = "Microsoft.Cache/redis"
    metric_name      = "usedmemorypercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "redis_server_load" {
  name                = "${var.project_name}-${var.environment}-redis-load"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_redis_cache.main.id]
  description         = "Alert when Redis server load is high"

  criteria {
    metric_namespace = "Microsoft.Cache/redis"
    metric_name      = "serverLoad"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.common_tags
}