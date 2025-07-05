variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, production)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for AKS"
  type        = string
}

# Optional overrides
variable "node_count" {
  description = "Number of nodes (used when autoscaling is disabled)"
  type        = number
  default     = 1
}

variable "node_size" {
  description = "VM size for nodes (defaults to B2s for dev, D2s_v3 for prod)"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version (leave empty for latest)"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable monitoring (defaults to true for all environments)"
  type        = bool
  default     = true  # Changed from false to true
}

variable "enable_autoscaling" {
  description = "Enable autoscaling (forced true for production)"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = ""
}

variable "admin_group_ids" {
  description = "Azure AD admin group IDs"
  type        = list(string)
  default     = []
}

variable "additional_node_labels" {
  description = "Additional node labels"
  type        = map(string)
  default     = {}
}

# Production-specific options
variable "create_user_node_pool" {
  description = "Create separate user node pool (production only)"
  type        = bool
  default     = false
}

variable "user_node_size" {
  description = "VM size for user node pool"
  type        = string
  default     = ""
}

variable "user_node_taints" {
  description = "Taints for user node pool"
  type        = list(string)
  default     = ["workload=applications:NoSchedule"]
}

variable "enable_acr_geo_replication" {
  description = "Enable ACR geo-replication (production only)"
  type        = bool
  default     = false
}

variable "acr_geo_replications" {
  description = "List of regions for ACR geo-replication"
  type        = list(string)
  default     = ["West Europe"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}