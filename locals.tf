locals {
  environment             = var.environment
  project_name            = var.project_name
  resource_prefix         = "${local.environment}${local.project_name}"
  azure_location          = var.azure_location
  existing_resource_group = var.existing_resource_group
  resource_group          = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : data.azurerm_resource_group.existing_resource_group[0]

  cdn_sku         = var.cdn_sku
  cdn_waf_targets = var.cdn_waf_targets
  cdn_custom_domains = {
    for cdn_waf_target_name, cdn_waf_target_value in local.cdn_waf_targets : cdn_waf_target_name => cdn_waf_target_value.fqdn if cdn_waf_target_value.create_custom_domain
  }
  cdn_response_timeout          = var.cdn_response_timeout
  cdn_host_redirects            = var.cdn_host_redirects
  cdn_host_add_response_headers = var.cdn_host_add_response_headers
  cdn_remove_response_headers   = var.cdn_remove_response_headers

  existing_monitor_action_group_id = var.existing_monitor_action_group_id
  enable_cdn_latency_monitor       = var.enable_cdn_latency_monitor
  cdn_latency_monitor_threshold    = var.cdn_latency_monitor_threshold

  enable_waf                            = var.enable_waf
  waf_managed_rulesets                  = var.waf_managed_rulesets
  waf_custom_rules                      = var.waf_custom_rules
  waf_mode                              = var.waf_mode
  waf_custom_block_response_status_code = var.waf_custom_block_response_status_code
  waf_custom_block_response_body        = var.waf_custom_block_response_body
  waf_enable_rate_limiting              = var.waf_enable_rate_limiting
  waf_rate_limiting_duration_in_minutes = var.waf_rate_limiting_duration_in_minutes
  waf_rate_limiting_threshold           = var.waf_rate_limiting_threshold
  waf_rate_limiting_bypass_ip_list      = var.waf_rate_limiting_bypass_ip_list
  waf_rate_limiting_action              = var.waf_rate_limiting_action

  tags = var.tags
}
