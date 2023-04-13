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

  tags = var.tags
}
