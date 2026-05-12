resource "azurerm_storage_account" "custom_error" {
  #checkov:skip=CKV_AZURE_59: "Ensure that Storage accounts disallow public access"
  #checkov:skip=CKV_AZURE_33: "Ensure Storage logging is enabled for Queue service for read, write and delete requests"
  #checkov:skip=CKV_AZURE_190: "Ensure that Storage blobs restrict public access"
  #checkov:skip=CKV_AZURE_206: "Ensure that Storage Accounts use replication"
  #checkov:skip=CKV2_AZURE_41: "Ensure storage account is configured with SAS expiration policy"
  #checkov:skip=CKV2_AZURE_40: "Ensure storage account is not configured with Shared Key authorization"
  #checkov:skip=CKV2_AZURE_1: "Ensure storage for critical data are encrypted with Customer Managed Key"
  #checkov:skip=CKV2_AZURE_47: "Ensure storage account is configured without blob anonymous access"
  #checkov:skip=CKV2_AZURE_33: "Ensure storage account is configured with private endpoint"

  for_each = { for k, v in local.waf_targets : k => v if v["custom_errors"] != null }

  name                          = "${replace(local.environment, "-", "")}staticwebsite${substr(sha1(each.key), 0, 4)}"
  resource_group_name           = local.resource_prefix
  location                      = local.azure_location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
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

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  sas_policy {
    expiration_period = "02.00:00:00"
  }

  tags = merge(local.tags, {
    "waf_target" = each.key
  })
}

resource "azapi_update_resource" "container_app_storage_key_rotation_reminder" {
  for_each = { for k, v in local.waf_targets : k => v if v["custom_errors"] != null }

  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = azurerm_storage_account.custom_error[each.key].id
  body = jsonencode({
    properties = {
      keyPolicy : {
        keyExpirationPeriodInDays : 90
      }
    }
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
