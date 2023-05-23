resource "azurerm_monitor_metric_alert" "cdn" {
  count = local.waf_application == "CDN" && local.enable_latency_monitor && local.existing_monitor_action_group_id != "" ? 1 : 0

  name                = "${azurerm_cdn_frontdoor_profile.waf[0].name}-latency"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_cdn_frontdoor_profile.waf[0].id]
  description         = "Action will be triggered when Origin latency is higher than ${local.latency_monitor_threshold}ms"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Minimum"
    operator         = "GreaterThan"
    threshold        = local.latency_monitor_threshold
  }

  action {
    action_group_id = local.existing_monitor_action_group_id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "app_gateway_v2" {
  count = local.waf_application == "AppGatewayV2" && local.enable_latency_monitor && local.existing_monitor_action_group_id != "" ? 1 : 0

  name                = "${azurerm_application_gateway.waf[0].name}-latency"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_application_gateway.waf[0].id]
  description         = "Action will be triggered when backend connection time is higher than ${local.latency_monitor_threshold}ms"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Network/applicationgateways"
    metric_name      = "BackendConnectTime"
    aggregation      = "Minimum"
    operator         = "GreaterThan"
    threshold        = local.latency_monitor_threshold
  }

  action {
    action_group_id = local.existing_monitor_action_group_id
  }

  tags = local.tags
}
