resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  count = local.enable_waf ? 1 : 0

  name                              = "${replace(local.resource_prefix, "-", "")}waf"
  resource_group_name               = local.resource_group.name
  sku_name                          = azurerm_cdn_frontdoor_profile.cdn.sku_name
  enabled                           = true
  mode                              = local.waf_mode
  custom_block_response_status_code = 403
  custom_block_response_body        = filebase64("${path.module}/html/403.html")

  dynamic "custom_rule" {
    for_each = local.enable_rate_limiting ? [0] : []
    content {
      name                           = "RateLimiting"
      enabled                        = true
      priority                       = 1
      rate_limit_duration_in_minutes = local.rate_limiting_duration_in_minutes
      rate_limit_threshold           = local.rate_limiting_threshold
      type                           = "RateLimitRule"
      action                         = "Block"

      dynamic "match_condition" {
        for_each = length(local.rate_limiting_bypass_ip_list) > 0 ? [0] : []

        content {
          match_variable     = "RemoteAddr"
          operator           = "IPMatch"
          negation_condition = true
          match_values       = local.rate_limiting_bypass_ip_list
        }
      }

      match_condition {
        match_variable     = "RequestUri"
        operator           = "RegEx"
        negation_condition = false
        match_values       = ["/.*"]
      }

    }
  }

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "waf" {
  count = local.enable_waf ? 1 : 0

  name                     = "${replace(local.resource_prefix, "-", "")}wafsecuritypolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf[0].id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
        }

        dynamic "domain" {
          for_each = toset(local.custom_domains)

          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[domain.value].id
          }
        }
      }
    }
  }
}
