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

  name                     = substr("${local.resource_prefix}-${each.key}", 0, 46)
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

resource "azurerm_cdn_frontdoor_rule_set" "redirects" {
  count = length(local.cdn_host_redirects) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}redirects"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id
}

resource "azurerm_cdn_frontdoor_rule" "redirect" {
  for_each = { for index, host_redirect in local.cdn_host_redirects : index => { "from" : host_redirect.from, "to" : host_redirect.to } }

  depends_on = [azurerm_cdn_frontdoor_origin_group.waf, azurerm_cdn_frontdoor_origin.waf]

  name                      = "redirect${each.key}"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.redirects[0].id
  order                     = each.key
  behavior_on_match         = "Continue"

  actions {
    url_redirect_action {
      redirect_type        = "Moved"
      redirect_protocol    = "Https"
      destination_hostname = each.value.to
    }
  }

  conditions {
    host_name_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = [each.value.from]
      transforms       = ["Lowercase", "Trim"]
    }
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "add_response_headers" {
  count = length(local.cdn_host_add_response_headers) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}addresponseheaders"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id
}

resource "azurerm_cdn_frontdoor_rule" "add_response_headers" {
  for_each = { for index, response_header in local.cdn_host_add_response_headers : index => { "name" : response_header.name, "value" : response_header.value } }

  depends_on = [azurerm_cdn_frontdoor_origin_group.waf, azurerm_cdn_frontdoor_origin.waf]

  name                      = replace("addresponseheaders${each.key}", "-", "")
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.add_response_headers[0].id
  order                     = 0
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Overwrite"
      header_name   = each.value.name
      value         = each.value.value
    }
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "remove_response_headers" {
  count = length(local.cdn_remove_response_headers) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}removeresponseheaders"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id
}

resource "azurerm_cdn_frontdoor_rule" "remove_response_header" {
  for_each = toset(local.cdn_remove_response_headers)

  depends_on = [azurerm_cdn_frontdoor_origin_group.waf, azurerm_cdn_frontdoor_origin.waf]

  name                      = replace("removeresponseheader${each.value}", "-", "")
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.remove_response_headers[0].id
  order                     = 0
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Delete"
      header_name   = each.value
    }
  }
}
