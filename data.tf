data "azurerm_resource_group" "existing_resource_group" {
  count = local.existing_resource_group == "" ? 0 : 1

  name = local.existing_resource_group
}

data "azurerm_client_config" "current" {}

data "azuread_service_principal" "frontdoor" {
  display_name = "Microsoft.Azure.Cdn"
}
