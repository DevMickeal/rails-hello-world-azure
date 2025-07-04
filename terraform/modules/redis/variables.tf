
variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "redis_subnet_id" { type = string }
variable "capacity" { type = number }
variable "family" { type = string }
variable "sku_name" { type = string }
variable "shard_count" { type = number }
variable "key_vault_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "common_tags" { type = map(string) }

variable "maxmemory_reserved" { type = number }
variable "maxmemory_delta" { type = number }
variable "backup_storage_connection_string" { type = string }
variable "redis_dns_zone_id" { type = string }
variable "action_group_id" { type = string }
