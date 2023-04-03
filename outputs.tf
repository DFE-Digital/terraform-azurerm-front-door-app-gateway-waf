output "environment" {
  value = local.environment
}

output "azurerm_resource_group_default" {
  value       = local.resource_group
  description = "Default Azure Resource Group"
}
