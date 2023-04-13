resource "azurerm_monitor_metric_alert" "cdn_latency" {
  count = local.enable_cdn_latency_monitor && local.existing_monitor_action_group_id != "" ? 1 : 0

  name                = "${azurerm_cdn_frontdoor_profile.waf.name}-latency"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_cdn_frontdoor_profile.waf.id]
  description         = "Action will be triggered when Origin latency is higher than ${local.cdn_latency_monitor_threshold}ms"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = local.cdn_latency_monitor_threshold
  }

  action {
    action_group_id = local.existing_monitor_action_group_id
  }

  tags = local.tags
}
