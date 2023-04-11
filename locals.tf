locals {
  environment                = var.environment
  project_name               = var.project_name
  resource_prefix            = "${local.environment}${local.project_name}"
  azure_location             = var.azure_location
  existing_resource_group    = var.existing_resource_group
  resource_group             = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : data.azurerm_resource_group.existing_resource_group[0]
  tags                       = var.tags
  sku                        = var.sku
  enable_latency_monitor     = var.enable_latency_monitor
  alarm_latency_threshold_ms = var.alarm_latency_threshold_ms
  monitor_action_group_id    = var.monitor_action_group_id
  response_timeout           = var.response_timeout

  endpoints = var.endpoints
  targets = flatten([for k, o in var.endpoints : [for _o in o.targets : {
    name : "${k}${index(o.targets, _o)}",
    host_name : _o,
    origin_group_name : k
  }]])
  domains = flatten([for k, o in var.endpoints : [for _o in o.domains : {
    name : "${k}${index(o.domains, _o)}",
    host_name : _o,
    route_name : k
  }]])
  routes = flatten([for r, o in var.endpoints : {
    cdn_frontdoor_origin_ids : [for origin in o.targets : "${r}${index(o.targets, origin)}"]
    https_redirect_enabled : try(o.https_redirect_enabled, true),
    cdn_frontdoor_custom_domain_ids : [for domain in o.domains : "${r}${index(o.domains, domain)}"]
    name : r,
    origin_group_name : r
  }])

  host_redirects                     = var.host_redirects
  host_add_response_headers          = var.host_add_response_headers
  remove_response_headers            = var.remove_response_headers
  ruleset_redirects_id               = length(local.host_redirects) > 0 ? [azurerm_cdn_frontdoor_rule_set.redirects[0].id] : []
  ruleset_add_response_headers_id    = length(local.host_add_response_headers) > 0 ? [azurerm_cdn_frontdoor_rule_set.add_response_headers[0].id] : []
  ruleset_remove_response_headers_id = length(local.remove_response_headers) > 0 ? [azurerm_cdn_frontdoor_rule_set.remove_response_headers[0].id] : []
  ruleset_ids = concat(
    local.ruleset_redirects_id,
    local.ruleset_add_response_headers_id,
    local.ruleset_remove_response_headers_id,
  )
  enable_waf                            = var.enable_waf
  waf_managed_rulesets                  = var.waf_managed_rulesets
  waf_custom_rules                      = var.waf_custom_rules
  waf_mode                              = var.waf_mode
  waf_enable_rate_limiting              = var.waf_enable_rate_limiting
  waf_rate_limiting_duration_in_minutes = var.waf_rate_limiting_duration_in_minutes
  waf_rate_limiting_threshold           = var.waf_rate_limiting_threshold
  waf_rate_limiting_bypass_ip_list      = var.waf_rate_limiting_bypass_ip_list
}
