
variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "kubernetes_version" { type = string }
variable "os_disk_size_gb" { type = number }
variable "system_node_count" { type = number }
variable "system_node_size" { type = string }
variable "system_node_min_count" { type = number }
variable "system_node_max_count" { type = number }
variable "system_node_max_pods" { type = number }
variable "user_node_count" { type = number }
variable "user_node_size" { type = string }
variable "user_node_min_count" { type = number }
variable "user_node_max_count" { type = number }
variable "aks_subnet_id" { type = string }
variable "acr_sku" { type = string }
variable "common_tags" { type = map(string) }

# Additional variables for AKS module
variable "admin_group_object_ids" { type = list(string) }
variable "log_analytics_workspace_id" { type = string }
variable "appgw_subnet_id" { type = string }
variable "key_vault_id" { type = string }
