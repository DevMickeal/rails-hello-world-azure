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
