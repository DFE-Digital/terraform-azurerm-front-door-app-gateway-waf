resource "azurerm_monitor_metric_alert" "latency" {
  count = local.enable_latency_monitor ? 1 : 0

  name                = "${azurerm_cdn_frontdoor_profile.cdn.name}-latency"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_cdn_frontdoor_profile.cdn.id]
  description         = "Action will be triggered when Origin latency is higher than ${local.alarm_latency_threshold_ms}ms"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    # 1,000ms = 1s
    threshold = local.alarm_latency_threshold_ms
  }

  action {
    action_group_id = local.monitor_action_group_id
  }

  tags = local.tags
}
