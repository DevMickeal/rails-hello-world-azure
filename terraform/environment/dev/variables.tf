variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "azure_client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}


variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "railsapp"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
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

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
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
