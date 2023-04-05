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
  target_resource_id             = azurerm_cdn_frontdoor_profile.waf.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.waf.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "FrontdoorWebApplicationFirewallLog"

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
