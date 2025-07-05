variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "railsapp"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "northeurope"
}

variable "allowed_ips" {
  description = "List of allowed IP addresses for Key Vault"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "aks_admin_group_ids" {
  description = "Azure AD group IDs for AKS administrators"
  type        = list(string)
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "owner_email" {
  description = "Email of the resource owner"
  type        = string
}

variable "database_sku" {
  description = "Database SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "database_storage_mb" {
  description = "Database storage in MB"
  type        = number
  default     = 32768
}