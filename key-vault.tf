resource "azurerm_key_vault" "frontdoor" {
  count = local.use_existing_key_vault ? 0 : 1

  name                       = "${local.resource_prefix}fdkv"
  location                   = local.resource_group.location
  resource_group_name        = local.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
  }

  # CDN Front Door Enterprise Application Object ID(e.g. Microsoft.Azure.Cdn)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_service_principal.frontdoor.object_id

    secret_permissions = [
      "Get",
    ]
  }

  # Terraform Service Principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id # <- Object Id of the Service Principal that Terraform is running as

    certificate_permissions = [
      "Get",
      "Import",
      "Delete",
      "Purge"
    ]

    secret_permissions = [
      "Get",
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
