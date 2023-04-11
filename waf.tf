resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                              = "${replace(local.resource_prefix, "-", "")}waf"
  resource_group_name               = local.resource_group.name
  sku_name                          = azurerm_cdn_frontdoor_profile.waf.sku_name
  enabled                           = local.enable_waf
  mode                              = local.waf_mode
  custom_block_response_status_code = 403
  custom_block_response_body        = filebase64("${path.module}/html/403.html")

  dynamic "custom_rule" {
    for_each = local.waf_enable_rate_limiting ? [1] : []

    content {
      name                           = "RateLimiting"
      enabled                        = true
      priority                       = 1
      rate_limit_duration_in_minutes = local.waf_rate_limiting_duration_in_minutes
      rate_limit_threshold           = local.waf_rate_limiting_threshold
      type                           = "RateLimitRule"
      action                         = local.waf_mode == "Prevention" ? "Block" : "Log"

      dynamic "match_condition" {
        for_each = length(local.waf_rate_limiting_bypass_ip_list) > 0 ? [1] : []

        content {
          match_variable     = "RemoteAddr"
          operator           = "IPMatch"
          negation_condition = true
          match_values       = local.waf_rate_limiting_bypass_ip_list
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

  dynamic "custom_rule" {
    for_each = local.waf_custom_rules

    content {
      name     = custom_rule.key
      enabled  = true
      priority = custom_rule.value["priority"]
      type     = "MatchRule"
      action   = custom_rule.value["action"]

      dynamic "match_condition" {
        for_each = custom_rule.value["conditions"]

        content {
          match_variable = match_condition.value["variable"]
          match_values   = match_condition.value["values"]
          operator       = match_condition.value["operator"]
          selector       = lookup(match_condition.value, "selector", "")
        }
      }
    }
  }

  dynamic "managed_rule" {
    for_each = local.waf_managed_rulesets

    content {
      type    = managed_rule.key
      version = managed_rule.value["version"]
      action  = managed_rule.value["action"]

      dynamic "override" {
        for_each = lookup(managed_rule.value, "overrides", {})

        content {
          rule_group_name = override.key

          dynamic "rule" {
            for_each = override.value

            content {
              rule_id = rule.key
              enabled = true
              action  = rule.value["action"]

              dynamic "exclusion" {
                for_each = lookup(rule.value, "exclusions", [])

                content {
                  match_variable = exclusion.value["match_variable"]
                  operator       = exclusion.value["operator"]
                  selector       = exclusion.value["selector"]
                }
              }
            }
          }
        }
      }
    }
  }

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "waf" {
  name                     = "${replace(local.resource_prefix, "-", "")}wafsecuritypolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.waf.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf.id

      association {
        patterns_to_match = ["/*"]

        dynamic "domain" {
          for_each = local.endpoints

          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint[domain.key].id
          }
        }

        dynamic "domain" {
          for_each = try({ for domain in local.domains : domain.name => domain }, {})

          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[domain.key].id
          }
        }
      }
    }
  }
}
