output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.networking.resource_group_name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_resource_group" {
  description = "Resource group for AKS"
  value       = azurerm_resource_group.main.name
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.security.key_vault_name
}

output "aks_get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${module.networking.resource_group_name} --name ${module.aks.cluster_name}"
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.aks.acr_login_server
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.monitoring.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "postgres_server_name" {
  description = "PostgreSQL server name"
  value       = module.database.server_name
}