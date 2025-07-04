output "resource_group_name" {
  value = azurerm_virtual_network.main.resource_group_name
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}
output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}
output "database_subnet_id" {
  value = azurerm_subnet.database.id
}
output "redis_subnet_id" {
  value = azurerm_subnet.redis.id
}
output "postgres_dns_zone_id" {
  value = azurerm_private_dns_zone.postgres.id
}
output "redis_dns_zone_id" {
  value = azurerm_private_dns_zone.redis.id
}
