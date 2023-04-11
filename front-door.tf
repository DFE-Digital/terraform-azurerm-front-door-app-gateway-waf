resource "azurerm_cdn_frontdoor_profile" "waf" {
  name                     = "${local.resource_prefix}cdnwaf"
  resource_group_name      = local.resource_group.name
  sku_name                 = local.sku
  response_timeout_seconds = local.response_timeout
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "group" {
  for_each = local.endpoints

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id

  load_balancing {}

  dynamic "health_probe" {
    for_each = lookup(each.value, "enable_health_probe", true) ? [1] : []

    content {
      protocol            = "Https"
      interval_in_seconds = lookup(each.value, "health_probe_interval", 60)
      request_type        = lookup(each.value, "health_probe_request_type", "HEAD")
      path                = lookup(each.value, "health_probe_path", "/")
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  for_each = try({ for origin in local.targets : origin.name => origin }, {})

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
  for_each = local.endpoints

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each = try({ for domain in local.domains : domain.name => domain }, {})

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id
  host_name                = each.value.host_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "route" {
  for_each = try({ for route in local.routes : route.name => route }, {})

  name                          = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint[each.value.origin_group_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.group[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids = [
    for origin in each.value.cdn_frontdoor_origin_ids : azurerm_cdn_frontdoor_origin.origin[origin].id
  ]
  cdn_frontdoor_rule_set_ids = local.ruleset_ids
  enabled                    = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = lookup(each.value, "https_redirect_enabled", true)
  patterns_to_match      = ["/*"]
  supported_protocols    = lookup(each.value, "https_redirect_enabled", true) ? ["Http", "Https"] : ["Http"]

  cdn_frontdoor_custom_domain_ids = [
    for domain_id in each.value.cdn_frontdoor_custom_domain_ids : azurerm_cdn_frontdoor_custom_domain.custom_domain[domain_id].id
  ]

  link_to_default_domain = true
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "custom_domain_association" {
  for_each = try({ for domain in local.domains : domain.name => domain }, {})

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[each.value.name].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.route[each.value.route_name].id]
}
