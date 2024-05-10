resource "azurerm_storage_account" "custom_error" {
  for_each = { for k, v in local.waf_targets : k => v if v["custom_errors"] != null }

  name                          = "staticwebsite${substr(sha1(each.key), 0, 8)}"
  resource_group_name           = local.resource_prefix
  location                      = local.azure_location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  enable_https_traffic_only     = true
  public_network_access_enabled = true

  static_website {}

  tags = local.tags
}

resource "azurerm_storage_container" "custom_error_web" {
  for_each = { for k, v in local.waf_targets : k => v if v["custom_errors"] != null }

  name                  = "$web"
  storage_account_name  = azurerm_storage_account.custom_error[each.key].name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "custom_error_web_pages" {
  for_each = merge([
    for k, v in local.waf_targets : {
      for error_page_key, error_page_value in fileset(v["custom_errors"]["error_page_directory"], "**") : "${k}_${error_page_key}" => {
        error_page     = error_page_value,
        waf_target_key = k
      }
    } if v["custom_errors"] != null
  ]...)

  name                   = each.value["error_page"]
  storage_account_name   = azurerm_storage_account.custom_error[each.value["waf_target_key"]].name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${local.waf_targets[each.value["waf_target_key"]]["custom_errors"]["error_page_directory"]}/${each.value["error_page"]}"
  content_md5            = filemd5("${local.waf_targets[each.value["waf_target_key"]]["custom_errors"]["error_page_directory"]}/${each.value["error_page"]}")
  access_tier            = "Cool"
}
