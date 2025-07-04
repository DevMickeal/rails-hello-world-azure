output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.networking.resource_group_name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${module.networking.resource_group_name} --name ${module.aks.cluster_name}"
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.aks.acr_login_server
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.security.key_vault_name
}

output "postgres_server_name" {
  description = "PostgreSQL server name"
  value       = module.database.server_name
}

output "redis_hostname" {
  description = "Redis hostname"
  value       = module.redis.hostname
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
