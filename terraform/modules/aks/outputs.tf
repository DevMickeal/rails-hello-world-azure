output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "acr_login_server" {
  description = "ACR login server"
  value       = azurerm_container_registry.main.login_server
}

output "acr_id" {
  description = "ACR resource ID"
  value       = azurerm_container_registry.main.id
}

output "acr_admin_username" {
  description = "ACR admin username (dev/staging only)"
  value       = azurerm_container_registry.main.admin_enabled ? azurerm_container_registry.main.admin_username : null
}

output "acr_admin_password" {
  description = "ACR admin password (dev/staging only)"
  value       = azurerm_container_registry.main.admin_enabled ? azurerm_container_registry.main.admin_password : null
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet identity for role assignments"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}