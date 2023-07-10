data "azurerm_resource_group" "existing_resource_group" {
  count = local.existing_resource_group == "" ? 0 : 1

  name = local.existing_resource_group
}

data "azurerm_virtual_network" "existing_virtual_network" {
  count = local.existing_virtual_network == "" ? 0 : 1

  name                = local.existing_virtual_network
  resource_group_name = local.existing_resource_group
}

data "azurerm_client_config" "current" {}

data "azuread_user" "key_vault_app_gateway_certificates_access" {
  for_each = local.key_vault_app_gateway_certificates_access_users

  user_principal_name = each.value
}

data "azurerm_user_assigned_identity" "app_gateway_v2" {
  for_each = local.app_gateway_v2_identity_names

  name                = each.value
  resource_group_name = local.resource_group.name
}
