resource "azurerm_cdn_frontdoor_profile" "cdn" {
  name                     = "${local.resource_prefix}cdn"
  resource_group_name      = local.resource_group.name
  sku_name                 = local.sku
  response_timeout_seconds = local.response_timeout
  tags                     = local.tags
}

resource "azapi_update_resource" "frontdoor_system_identity" {
  type        = "Microsoft.Cdn/profiles@2023-02-01-preview"
  resource_id = azurerm_cdn_frontdoor_profile.cdn.id
  body = jsonencode({
    "identity" : {
      "type" : "SystemAssigned"
    }
  })

  response_export_values = ["identity.principalId"]
}

resource "azurerm_cdn_frontdoor_origin_group" "group" {
  for_each = local.origin_groups

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id

  load_balancing {}

  dynamic "health_probe" {
    for_each = each.value.enable_health_probe ? [0] : []

    content {
      protocol            = "Https"
      interval_in_seconds = each.value.health_probe_interval
      request_type        = each.value.health_probe_request_type
      path                = each.value.health_probe_path
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  for_each = try({ for origin in local.origin_map : origin.name => origin }, {})

  name                           = "${local.resource_prefix}origin-${each.key}"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.group[each.value.origin_group_name].id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = each.value.host_name
  origin_host_header             = each.value.host_name
  http_port                      = 80
  https_port                     = 443
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  for_each = local.origin_groups

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each = try({ for domain in local.domain_map : domain.name => domain }, {})

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id
  host_name                = each.value.host_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "route" {
  for_each = try({ for route in local.route_map : route.name => route }, {})

  name                          = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint[each.value.origin_group_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.group[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids = [
    for origin in each.value.cdn_frontdoor_origin_ids : azurerm_cdn_frontdoor_origin.origin[origin].id
  ]
  cdn_frontdoor_rule_set_ids = local.ruleset_ids
  enabled                    = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = each.value.https_redirect_enabled
  patterns_to_match      = ["/*"]
  supported_protocols    = each.value.https_redirect_enabled ? ["Http", "Https"] : ["Http"]

  cdn_frontdoor_custom_domain_ids = [
    for domain_id in each.value.cdn_frontdoor_custom_domain_ids : azurerm_cdn_frontdoor_custom_domain.custom_domain[domain_id].id
  ]

  link_to_default_domain = true
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "custom_domain_association" {
  for_each = try({ for domain in local.domain_map : domain.name => domain }, {})

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[each.value.name].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.route[each.value.route_name].id]
}

resource "azurerm_cdn_frontdoor_secret" "frontdoor" {
  for_each = local.certificates

  name                     = "${local.resource_prefix}secret${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id

  secret {
    customer_certificate {
      key_vault_certificate_id = azurerm_key_vault_certificate.frontdoor[each.key].versionless_id # latest
    }
  }

  # Can't set the Secret unless we have the correct permission set first
  depends_on = [
    azurerm_key_vault_access_policy.user
  ]
}
