variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "allowed_ips" { type = list(string) }
variable "allowed_subnet_ids" { type = list(string) }
variable "aks_cluster_id" { type = string }
variable "common_tags" { type = map(string) }
