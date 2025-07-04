output "instrumentation_key" {
  value = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "connection_string" {
  value = azurerm_application_insights.main.connection_string
  sensitive = true
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.workspace_id
}
