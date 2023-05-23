resource "azurerm_log_analytics_workspace" "waf" {
  name                = "${local.resource_prefix}waf"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "waf" {
  name                           = "${local.resource_prefix}waf"
  target_resource_id             = local.waf_application == "CDN" ? azurerm_cdn_frontdoor_profile.waf[0].id : azurerm_application_gateway.waf[0].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.waf.id
  log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category = local.waf_application == "CDN" ? "FrontdoorWebApplicationFirewallLog" : "ApplicationGatewayFirewallLog"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}
