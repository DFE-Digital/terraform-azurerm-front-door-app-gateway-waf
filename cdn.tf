resource "azurerm_cdn_frontdoor_profile" "waf" {
  name                     = "${local.resource_prefix}cdnwaf"
  resource_group_name      = local.resource_group.name
  sku_name                 = local.cdn_sku
  response_timeout_seconds = local.cdn_response_timeout
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "waf" {
  for_each = local.cdn_waf_targets

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

resource "azurerm_cdn_frontdoor_origin" "waf" {
  for_each = local.cdn_waf_targets

  name                           = "${local.resource_prefix}origin-${each.key}"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.waf[each.key].id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = each.value.domain
  origin_host_header             = each.value.domain
  http_port                      = 80
  https_port                     = 443
}

resource "azurerm_cdn_frontdoor_endpoint" "waf" {
  for_each = local.cdn_waf_targets

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_custom_domain" "waf" {
  for_each = local.cdn_custom_domains

  name                     = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id
  host_name                = each.value

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "waf" {
  for_each = local.cdn_waf_targets

  name                          = "${local.resource_prefix}-${each.key}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.waf[each.key].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.waf[each.key].id
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.waf[each.key].id
  ]
  enabled = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = lookup(local.cdn_custom_domains, each.key, "") != "" ? [azurerm_cdn_frontdoor_custom_domain.waf[each.key].id] : null

  link_to_default_domain = true
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "waf" {
  for_each = local.cdn_custom_domains

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.waf[each.key].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.waf[each.key].id]
}
