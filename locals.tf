locals {
  environment                        = var.environment
  project_name                       = var.project_name
  resource_prefix                    = "${local.environment}${local.project_name}"
  azure_location                     = var.azure_location
  existing_resource_group            = var.existing_resource_group
  resource_group                     = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : data.azurerm_resource_group.existing_resource_group[0]
  tags                               = var.tags
  sku                                = var.sku
  enable_latency_monitor             = var.enable_latency_monitor
  alarm_latency_threshold_ms         = var.alarm_latency_threshold_ms
  monitor_action_group_id            = var.monitor_action_group_id
  enable_health_probe                = var.enable_health_probe
  health_probe_interval              = var.health_probe_interval
  health_probe_path                  = var.health_probe_path
  health_probe_request_type          = var.health_probe_request_type
  response_timeout                   = var.response_timeout
  origins                            = var.origins
  custom_domains                     = var.custom_domains
  use_existing_key_vault             = var.use_existing_key_vault
  existing_key_vault_id              = var.existing_key_vault_id
  key_vault_id                       = local.use_existing_key_vault ? local.existing_key_vault_id : azurerm_key_vault.frontdoor[0].id
  key_vault_allow_ipv4_list          = var.key_vault_allow_ipv4_list
  key_vault_access_users             = toset(var.key_vault_access_users)
  certificates                       = var.certificates
  https_redirect_enabled             = var.https_redirect_enabled
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
  waf_mode                              = var.waf_mode
  waf_enable_bot_protection             = var.waf_enable_bot_protection
  waf_use_preview_bot_ruleset           = var.waf_use_preview_bot_ruleset
  waf_enable_default_ruleset            = var.waf_enable_default_ruleset
  waf_use_new_default_ruleset           = var.waf_use_new_default_ruleset
  waf_enable_rate_limiting              = var.waf_enable_rate_limiting
  waf_rate_limiting_duration_in_minutes = var.waf_rate_limiting_duration_in_minutes
  waf_rate_limiting_threshold           = var.waf_rate_limiting_threshold
  waf_rate_limiting_bypass_ip_list      = var.waf_rate_limiting_bypass_ip_list
}
