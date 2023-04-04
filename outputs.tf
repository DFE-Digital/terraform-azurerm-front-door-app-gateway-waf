output "environment" {
  value = local.environment
}

output "azurerm_resource_group_default" {
  value       = local.resource_group
  description = "Default Azure Resource Group"
}

output "origin_groups" {
  value = azurerm_cdn_frontdoor_origin_group.group
  description = "List of all Origin Groups"
}

output "origins" {
  value = azurerm_cdn_frontdoor_origin.origin
  description = "List of all Origins"
}

output "custom_domains" {
  value= azurerm_cdn_frontdoor_custom_domain.custom_domain
  description = "List of all Custom Domain associations"
}

output "routes" {
  value = azurerm_cdn_frontdoor_route.route
  description = "List of all Routes"
}
