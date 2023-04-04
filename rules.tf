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
