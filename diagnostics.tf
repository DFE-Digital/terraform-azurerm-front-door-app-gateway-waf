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
  }

  enabled_log {
    category = local.waf_application == "CDN" ? "FrontdoorAccessLog" : "ApplicationGatewayAccessLog"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_action_group" "main" {
  name                = "${local.resource_prefix}-actiongroup"
  resource_group_name = local.resource_group.name
  short_name          = local.project_name
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = local.monitor_email_receivers

    content {
      name                    = "Email ${email_receiver.value}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "logic_app_receiver" {
    for_each = local.logic_app_workflow_name != "" ? [1] : []

    content {
      name                    = local.logic_app_workflow_name
      resource_id             = local.logic_app_workflow_id
      callback_url            = local.logic_app_workflow_callback_url
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "appgateway" {
  count = local.waf_application == "AppGatewayV2" && local.enable_waf_alert ? 1 : 0

  name                 = "${local.resource_prefix}waflogs"
  resource_group_name  = local.resource_group.name
  location             = local.resource_group.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT1H"
  scopes               = [azurerm_log_analytics_workspace.waf.id]
  severity             = 3
  description          = "Incoming request was blocked by a WAF Rule"

  criteria {
    query = <<-QUERY
      AzureDiagnostics
      | where ResourceProvider == "MICROSOFT.NETWORK" and Category == "ApplicationGatewayFirewallLog"
      | where (action_s == "Blocked" and Message !has "Inbound") or (action_s == "Matched" and ruleGroup_s != "UnknownBots")
      | extend request = parse_url(strcat("http://", hostname_s, requestUri_s))
      | project
          TimeGenerated,
          action_s,
          hostname_s,
          Host_s = split(hostname_s, ".")[0],
          path_s = request.Path,
          ruleSet_s = ruleSetType_s,
          ruleId_s,
          ruleGroup_s,
          Message,
          details_data_s
      | order by TimeGenerated
      QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThanOrEqual"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }

    dimension {
      name     = "action_s"
      operator = "Include"
      values = [
        "*"
      ]
    }

    dimension {
      name     = "hostname_s"
      operator = "Include"
      values = [
        "*"
      ]
    }

    dimension {
      name     = "ruleSet_s"
      operator = "Include"
      values = [
        "*"
      ]
    }
  }

  auto_mitigation_enabled = true

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
  }

  tags = local.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "frontdoor" {
  count = local.waf_application == "CDN" && local.enable_waf_alert ? 1 : 0

  name                 = "${local.resource_prefix}waflogs"
  resource_group_name  = local.resource_group.name
  location             = local.resource_group.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT1H"
  scopes               = [azurerm_log_analytics_workspace.waf.id]
  severity             = 3
  description          = "Incoming request was blocked by WAF Rule"

  criteria {
    query = <<-QUERY
      AzureDiagnostics
        | where ResourceProvider == "MICROSOFT.CDN" and Category == "FrontDoorWebApplicationFirewallLog"
        | where (action_s == "Blocked" and Message !has "Inbound") or (action_s == "Matched" and ruleGroup_s != "UnknownBots")
        | extend request = parse_url(strcat("http://", host_s, requestUri_s))
        | project
            TimeGenerated,
            action_s,
            host_s,
            Root_Host_s = split(host_s, ".")[0],
            path_s = request.Path,
            ruleSet_s = ruleSetType_s,
            ruleId_s,
            ruleGroup_s,
            details_msg_s,
            details_data_s
      QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThanOrEqual"

    dimension {
      name     = "action_s"
      operator = "Include"
      values = [
        "*"
      ]
    }

    dimension {
      name     = "host_s"
      operator = "Include"
      values = [
        "*"
      ]
    }

    dimension {
      name     = "ruleSet_s"
      operator = "Include"
      values = [
        "*"
      ]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled = true

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
  }

  tags = local.tags
}
