resource "azurerm_key_vault" "frontdoor" {
  count = local.use_existing_key_vault ? 0 : 1

  name                       = "${local.resource_prefix}-kv"
  location                   = local.resource_group.location
  resource_group_name        = local.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  dynamic "network_acls" {
    for_each = length(local.key_vault_allow_ipv4_list) > 0 ? [0] : []

    content {
      default_action = "Deny"
      bypass         = "AzureServices"
      ip_rules       = local.key_vault_allow_ipv4_list
    }
  }

  access_policy {
    tenant_id      = data.azurerm_client_config.current.tenant_id
    application_id = "205478c0-bd83-4e1b-a9d6-db63a3e1e1c8" # Microsoft.AzureFrontDoor-Cdn

    certificate_permissions = [
      "Get",
      "List",
      "Update",
      "Create",
      "Import",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "ManageContacts",
      "ManageIssuers",
      "GetIssuers",
      "ListIssuers",
      "SetIssuers",
      "DeleteIssuers",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
    ]
  }
}

resource "azurerm_key_vault_certificate" "frontdoor" {
  for_each = local.certificates

  name         = "${local.resource_prefix}cert${each.key}"
  key_vault_id = local.key_vault_id

  certificate {
    contents = each.value.contents
    password = each.value.password
  }
}
