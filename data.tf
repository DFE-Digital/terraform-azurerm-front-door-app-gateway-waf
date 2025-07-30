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

data "azurerm_logic_app_workflow" "existing_logic_app_workflow" {
  count = local.existing_logic_app_workflow.name == "" ? 0 : 1

  name                = local.existing_logic_app_workflow.name
  resource_group_name = local.existing_logic_app_workflow.resource_group_name
}

# There is not currently a way to get the full HTTP Trigger callback URL from a Logic App
# so we have to use AzAPI to query the Logic App Workflow for the value instead.
# https://github.com/hashicorp/terraform-provider-azurerm/issues/18866
data "azapi_resource_action" "existing_logic_app_workflow_callback_url" {
  count = local.existing_logic_app_workflow.name == "" ? 0 : 1

  resource_id = "${data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].id}/triggers/http-request-trigger"
  action      = "listCallbackUrl"
  type        = "Microsoft.Logic/workflows/triggers@2018-07-01-preview"

  depends_on = [
    data.azurerm_logic_app_workflow.existing_logic_app_workflow[0]
  ]

  response_export_values = ["value"]
}

data "azurerm_virtual_network" "vnet" {
  for_each = local.virtual_network_peering_targets

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}
