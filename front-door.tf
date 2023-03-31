resource "azurerm_cdn_frontdoor_profile" "cdn" {
  name                     = "${local.resource_prefix}cdn"
  resource_group_name      = local.resource_group.name
  sku_name                 = local.sku
  response_timeout_seconds = local.response_timeout
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "group" {
  name                     = "${local.resource_prefix}origingroup"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id

  load_balancing {}

  dynamic "health_probe" {
    for_each = local.enable_health_probe ? [0] : []

    content {
      protocol            = "Https"
      interval_in_seconds = local.health_probe_interval
      request_type        = local.health_probe_request_type
      path                = local.health_probe_path
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  for_each = local.origins

  name                           = "${local.resource_prefix}origin${each.key}"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.group.id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = each.value
  origin_host_header             = each.value
  http_port                      = 80
  https_port                     = 443
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${local.resource_prefix}cdnendpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each = local.custom_domains

  name                     = "${local.resource_prefix}custom-domain${index(local.custom_domains, each.value)}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id
  dns_zone_id              = length(each.value.dns_zone_id) ? each.value.dns_zone_id : null
  host_name                = each.value.host_name

  tls {
    certificate_type    = length(each.value.certificate_type) ? each.value.certificate_type : "ManagedCertificate"
    minimum_tls_version = length(each.value.min_tls_version) ? each.value.min_tls_version : "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "${local.resource_prefix}route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.group.id
  cdn_frontdoor_origin_ids      = [for o in azurerm_cdn_frontdoor_origin.origin : o.id]
  cdn_frontdoor_rule_set_ids    = local.ruleset_ids
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = local.https_redirect_enabled
  patterns_to_match      = ["/*"]
  supported_protocols    = local.https_redirect_enabled ? ["Http", "Https"] : ["Http"]

  cdn_frontdoor_custom_domain_ids = [
    for custom_domain in azurerm_cdn_frontdoor_custom_domain.custom_domain : custom_domain.id
  ]

  link_to_default_domain = true
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "custom_domain_association" {
  for_each = local.custom_domains

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[each.value].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.route.id]
}

resource "azurerm_cdn_frontdoor_rule_set" "redirects" {
  count = length(local.host_redirects) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}redirects"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id
}

resource "azurerm_cdn_frontdoor_rule" "redirect" {
  for_each = { for index, host_redirect in local.host_redirects : index => { "from" : host_redirect.from, "to" : host_redirect.to } }

  depends_on = [azurerm_cdn_frontdoor_origin_group.group, azurerm_cdn_frontdoor_origin.origin]

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
  count = length(local.host_add_response_headers) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}addresponseheaders"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id
}

resource "azurerm_cdn_frontdoor_rule" "add_response_headers" {
  for_each = { for index, response_header in local.host_add_response_headers : index => { "name" : response_header.name, "value" : response_header.value } }

  depends_on = [azurerm_cdn_frontdoor_origin_group.group, azurerm_cdn_frontdoor_origin.origin]

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
  count = length(local.remove_response_headers) > 0 ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}removeresponseheaders"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id
}

resource "azurerm_cdn_frontdoor_rule" "remove_response_header" {
  for_each = toset(local.remove_response_headers)

  depends_on = [azurerm_cdn_frontdoor_origin_group.group, azurerm_cdn_frontdoor_origin.origin]

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

resource "azurerm_cdn_frontdoor_secret" "frontdoor" {
  for_each = local.certificates

  name                     = "${local.resource_prefix}secret${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id

  secret {
    customer_certificate {
      key_vault_certificate_id = azurerm_key_vault_certificate.frontdoor[each.key].id
    }
  }
}
