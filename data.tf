data "azurerm_resource_group" "existing_resource_group" {
  count = local.existing_resource_group == "" ? 0 : 1

  name = local.existing_resource_group
}

data "azurerm_client_config" "current" {}

data "azuread_application" "frontdoor" {
  application_id = "ad0e1c7e-6d38-4ba4-9efd-0bc77ba9f037" # Microsoft.Azure.Frontdoor
}