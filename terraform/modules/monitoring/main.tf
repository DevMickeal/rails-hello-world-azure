# Azure Monitor and Application Insights configuration

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days

  tags = var.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  retention_in_days = var.retention_in_days
  sampling_percentage = var.environment == "production" ? 10 : 100

  tags = var.common_tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-${var.environment}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "${substr(var.project_name, 0, 9)}-${substr(var.environment, 0, 3)}"

  email_receiver {
    name                    = "sendtodevops"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = true
    }
  }

  tags = var.common_tags
}

# Storage Account for Logs and Backups
resource "azurerm_storage_account" "logs" {
  name                     = "${var.project_name}${var.environment}logs"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "GRS" : "LRS"
  
  # Removed invalid attributes and blocks. Add valid blocks as needed for your azurerm provider version.

  tags = var.common_tags
}

# Azure Monitor Workbook for Rails App
resource "azurerm_application_insights_workbook" "rails_dashboard" {
  # The name must be a valid UUID. Use uuidv5 for deterministic UUID based on project/environment/dashboard.
  name                = uuidv5("6ba7b810-9dad-11d1-80b4-00c04fd430c8", "${var.project_name}-${var.environment}-rails-dashboard")
  location            = var.location
  resource_group_name = var.resource_group_name
  display_name        = "Rails Application Dashboard"
  
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "# Rails Application Performance Dashboard"
        }
      },
      {
        type = 9
        content = {
          version = "KqlParameterItem/1.0"
          parameters = [
            {
              name = "TimeRange"
              type = 4
              value = {
                durationMs = 3600000
              }
            }
          ]
        }
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query = <<-EOT
            requests
            | where timestamp > ago(1h)
            | summarize RequestCount=count(), 
                       AvgDuration=avg(duration), 
                       P95Duration=percentile(duration, 95), 
                       P99Duration=percentile(duration, 99) 
                       by bin(timestamp, 1m)
            | render timechart
          EOT
          size = 0
          title = "Request Performance"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Log Analytics Solutions
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.common_tags
}

# Store monitoring keys in Key Vault
resource "azurerm_key_vault_secret" "appinsights_key" {
  name         = "${var.project_name}-${var.environment}-appinsights-key"
  value        = azurerm_application_insights.main.instrumentation_key
  key_vault_id = var.key_vault_id

  tags = var.common_tags
}