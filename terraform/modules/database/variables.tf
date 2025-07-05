variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "database_subnet_id" { type = string }
variable "administrator_login" { type = string }
variable "sku_name" { type = string }
variable "storage_mb" { type = number }
variable "backup_retention_days" { type = number }
variable "standby_availability_zone" { type = string }
variable "postgresql_version" { type = string }
variable "common_tags" { type = map(string) }
variable "postgresql_configurations" { type = map(string) }

# Additional variables for integration
variable "postgres_dns_zone_id" { type = string }
variable "key_vault_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "action_group_id" { type = string }