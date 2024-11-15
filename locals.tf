locals {
  environment              = var.environment
  project_name             = var.project_name
  resource_prefix          = "${local.environment}${local.project_name}"
  azure_location           = var.azure_location
  existing_resource_group  = var.existing_resource_group
  resource_group           = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : data.azurerm_resource_group.existing_resource_group[0]
  existing_virtual_network = var.existing_virtual_network
  create_virtual_network   = local.waf_application == "AppGatewayV2"
  virtual_network_name = local.existing_virtual_network == "" ? (
    local.create_virtual_network ? azurerm_virtual_network.default[0].name : ""
  ) : data.azurerm_virtual_network.existing_virtual_network[0].name
  virtual_network_address_space = var.virtual_network_address_space
  virtual_network_address_space_mask = element(split("/", local.virtual_network_address_space
  ), 1)
  app_gateway_v2_subnet_cidr  = cidrsubnet(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask, 0)
  app_gateway_v2_private_ip   = cidrhost(local.virtual_network_address_space, 23 - local.virtual_network_address_space_mask)
  app_gateway_v2_enable_http2 = var.app_gateway_v2_enable_http2

  app_gateway_v2_capacity_units                                           = var.app_gateway_v2_capacity_units
  app_gateway_v2_frontend_port                                            = var.app_gateway_v2_frontend_port
  app_gateway_v2_cookie_based_affinity                                    = var.app_gateway_v2_cookie_based_affinity
  restrict_app_gateway_v2_to_front_door_inbound_only                      = var.restrict_app_gateway_v2_to_front_door_inbound_only
  restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefixes = var.restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefixes
  restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefix   = var.restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefix
  app_gateway_v2_create_identity                                          = local.waf_application == "AppGatewayV2" && length(var.app_gateway_v2_identity_ids) == 0
  app_gateway_v2_identity_ids                                             = local.app_gateway_v2_create_identity ? [azurerm_user_assigned_identity.app_gateway[0].id] : var.app_gateway_v2_identity_ids
  app_gateway_v2_identity_names = toset([
    for name in var.app_gateway_v2_identity_ids : basename(name)
  ])
  app_gateway_v2_identity_principle_ids = concat(
    [
      for identity in data.azurerm_user_assigned_identity.app_gateway_v2 :
      identity.principal_id
    ],
    [
      for identity in azurerm_user_assigned_identity.app_gateway :
      identity.principal_id
    ]
  )
  app_gateway_v2_custom_error_configuration            = var.app_gateway_v2_custom_error_configuration
  enable_key_vault_app_gateway_certificates            = var.enable_key_vault_app_gateway_certificates
  key_vault_app_gateway_enable_rbac                    = var.key_vault_app_gateway_enable_rbac
  key_vault_app_gateway_certificates_access_users      = toset(var.key_vault_app_gateway_certificates_access_users)
  key_vault_app_gateway_certificates_access_ipv4       = var.key_vault_app_gateway_certificates_access_ipv4
  key_vault_app_gateway_certificates_access_subnet_ids = var.key_vault_app_gateway_certificates_access_subnet_ids

  cdn_sku     = var.cdn_sku
  waf_targets = var.waf_targets
  cdn_custom_domains = {
    for waf_target_name, waf_target_value in local.waf_targets : waf_target_name => waf_target_value.custom_fqdn if waf_target_value.cdn_create_custom_domain
  }
  response_request_timeout    = var.response_request_timeout
  cdn_host_redirects          = var.cdn_host_redirects
  cdn_url_path_redirects      = var.cdn_url_path_redirects
  cdn_add_response_headers    = var.cdn_add_response_headers
  cdn_remove_response_headers = var.cdn_remove_response_headers

  existing_monitor_action_group_id = var.existing_monitor_action_group_id
  enable_latency_monitor           = var.enable_latency_monitor
  latency_monitor_threshold        = var.latency_monitor_threshold

  enable_waf                                = var.enable_waf
  waf_application                           = var.waf_application
  enable_waf_alert                          = var.enable_waf_alert
  waf_custom_rules                          = var.waf_custom_rules
  waf_mode                                  = var.waf_mode
  cdn_waf_custom_block_response_status_code = var.cdn_waf_custom_block_response_status_code
  cdn_waf_custom_block_response_body        = var.cdn_waf_custom_block_response_body
  cdn_waf_managed_rulesets                  = var.cdn_waf_managed_rulesets

  app_gateway_v2_waf_file_upload_limit_in_mb     = var.app_gateway_v2_waf_file_upload_limit_in_mb
  app_gateway_v2_waf_max_request_body_size_in_kb = var.app_gateway_v2_waf_max_request_body_size_in_kb
  app_gateway_v2_waf_request_body_enforcement    = var.app_gateway_v2_waf_request_body_enforcement
  app_gateway_v2_waf_managed_rulesets            = var.app_gateway_v2_waf_managed_rulesets
  app_gateway_v2_waf_managed_rulesets_exclusions = var.app_gateway_v2_waf_managed_rulesets_exclusions

  cdn_waf_enable_rate_limiting              = var.cdn_waf_enable_rate_limiting
  cdn_waf_rate_limiting_duration_in_minutes = var.cdn_waf_rate_limiting_duration_in_minutes
  cdn_waf_rate_limiting_threshold           = var.cdn_waf_rate_limiting_threshold
  cdn_waf_rate_limiting_bypass_ip_list      = var.cdn_waf_rate_limiting_bypass_ip_list
  cdn_waf_rate_limiting_action              = var.cdn_waf_rate_limiting_action

  monitor_email_receivers         = var.monitor_email_receivers
  existing_logic_app_workflow     = var.existing_logic_app_workflow
  logic_app_workflow_name         = local.existing_logic_app_workflow.name == "" ? "" : data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].name
  logic_app_workflow_id           = local.existing_logic_app_workflow.name == "" ? "" : data.azurerm_logic_app_workflow.existing_logic_app_workflow[0].id
  logic_app_workflow_callback_url = local.existing_logic_app_workflow.name == "" ? "" : jsondecode(data.azapi_resource_action.existing_logic_app_workflow_callback_url[0].output).value

  content_types = {
    css   = "text/css"
    html  = "text/html"
    js    = "application/javascript"
    png   = "image/png"
    svg   = "image/svg+xml"
    woff  = "font/woff"
    woff2 = "font/woff2"
  }

  tags = var.tags
}
