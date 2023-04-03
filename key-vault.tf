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
    ip_rules       = local.key_vault_allow_ipv4_list
  }
}

resource "azurerm_key_vault_access_policy" "user" {
  for_each = data.azuread_user.key_vault_access

  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value["object_id"]
  key_vault_id = local.key_vault_id

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

resource "azurerm_key_vault_access_policy" "frontdoor" {
  key_vault_id   = local.key_vault_id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  object_id      = "119401db-410e-40ae-a7cb-c994e162b255" # Microsoft.AzureFrontDoor-Cdn
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

resource "azurerm_key_vault_certificate" "frontdoor" {
  for_each = local.certificates

  name         = "${local.resource_prefix}cert${each.key}"
  key_vault_id = local.key_vault_id

  certificate {
    contents = each.value.contents
    password = each.value.password
  }
}
