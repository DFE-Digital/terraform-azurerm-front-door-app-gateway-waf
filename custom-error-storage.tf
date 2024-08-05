resource "azurerm_storage_account" "custom_error" {
  for_each = { for k, v in local.waf_targets : k => v if v["custom_errors"] != null }

  name                          = "${replace(local.environment, "-", "")}staticwebsite${substr(sha1(each.key), 0, 4)}"
  resource_group_name           = local.resource_prefix
  location                      = local.azure_location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  enable_https_traffic_only     = true
  public_network_access_enabled = true

  static_website {}

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "OPTIONS"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 0
    }
  }

  sas_policy {
    expiration_period = "02.00:00:00"
  }

  tags = merge(local.tags, {
    "waf_target" = each.key
  })
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
  content_type           = lookup(local.content_types, element(split(".", each.value["error_page"]), length(split(".", each.value["error_page"])) - 1), null)
  access_tier            = "Cool"
}
