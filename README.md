# Azure WAF terraform module

[![Terraform CI](https://github.com/DFE-Digital/terraform-azurerm-front-door-app-gateway-waf/actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](https://github.com/DFE-Digital/terraform-azurerm-front-door-app-gateway-waf/actions/workflows/continuous-integration-terraform.yml?branch=main)

This module creates and manages an Azure Front Door/Application gateway, and associated WAF policy.

## Usage

Example module usage:

```hcl
module "azurerm_waf" {
  source  = "github.com/dfe-digital/terraform-azurerm-front-door-app-gateway-waf?ref=v1.4.0"

  ## General configuration
  environment    = "dev"
  project_name   = "waf"
  azure_location = "uksouth"
  existing_resource_group = "my-existing-rg"
  # existing_virtual_network = ""
  virtual_network_address_space = "172.16.0.0/12"
  # enable_latency_monitor = false
  # latency_monitor_threshold = 5000 # ms
  # response_request_timeout = 60 # seconds

  ## Web Application Firewall configuration
  enable_waf               = true
  waf_mode                 = "Prevention" # or "Detection"
  ## Choose whether to deploy an Azure Front Door, or an App Gateway
  waf_application  = "CDN" # or "AppGatewayV2"

  waf_targets = {
    "my-origin-name" = {
      domain = "my-fqdn.example.tld",
      # create_custom_domain = true,
      # enable_health_probe = true,
      # health_probe_interval = 60,
      # health_probe_request_type = "HEAD", # or "GET"
      # health_probe_path = "/",
      # cdn_add_response_headers = [
      #   {
      #     name = "X-Custom-Http-Header",
      #     value = "My-Favourite-Value"
      #   }
      # ],
      # cdn_add_request_headers = [
      #   {
      #     name = "X-Request-Header",
      #     value = "My-Favourite-Value"
      #   }
      # ],
      # cdn_remove_response_headers = [
      #   "X-Remove-This-Header"
      # ]
      # cdn_remove_request_headers = [
      #   "X-Remove-Me"
      # ],
      # custom_errors = {
      #   error_page_directory = "${path.root}/my-error-pages"
      #   error_pages = {
      #     "HttpStatus403" = "403.html",
      #     "HttpStatus502" = "502.html"
      #   }
      # }
    }
  }

  waf_custom_rules = {
    "PostParamValuesfoo" = {
      priority = 10,
      action = "Allow",
      match_conditions = {
        "allow-any-foo" = {
          match_variable = "PostArgs",
          match_values = []
          operator = "Any",
          selector = "foo"
        }
      }
    }
  }

  ## Azure Front Door specific configuration
  cdn_sku = "Premium_AzureFrontDoor" # or "Standard_AzureFrontDoor"
  # cdn_host_redirects = [
  #   "my-site-redirect" = {
  #     from = "example.com",
  #     to = "my.example.com"
  #   }
  # ]
  # cdn_url_path_redirects = [
  #   {
  #     "redirect_type" : "Moved",
  #     "redirect_protocol" : "Https"
  #     "destination_path" : "/example",
  #     "destination_hostname" : "www.example.com",
  #     "operator" : "Equal",
  #     "match_values" : ["/example"],
  #   }
  # ]
  ## Add custom HTTP Response Headers to all origins
  # cdn_add_response_headers = [
  #   {
  #     name = "X-Apply-To-All-Origins",
  #     value = "MyValue"
  #   }
  # ]
  ## Remove HTTP Response Headers from all origins
  # cdn_remove_response_headers = [
  #   "X-Remove-Me"
  # ]
  # cdn_waf_enable_rate_limiting              = false
  # cdn_waf_rate_limiting_duration_in_minutes = 5
  # cdn_waf_rate_limiting_threshold           = 1000
  # cdn_waf_rate_limiting_bypass_ip_list      = [ 1.1.1.1, 8.8.8.8 ]
  # cdn_waf_rate_limiting_action              = "Block" # one of "Allow", "Block", "Log"
  cdn_waf_managed_rulesets = {
    "BotProtection" = {
      version = "preview-0.1",
      action  = "Block"
    },
    "DefaultRuleSet" = {
      version = "1.0",
      action  = "Block"
      # overrides = {
      #   "SQLI" = {
      #     "942440" = { # SQL Comment Sequence Detected
      #       action = "Block"
      #       enabled = false # Optional - true by default
      #       exclusions = {
      #         "rcn-sw-cookies" = {
      #           match_variable = "RequestCookieNames"
      #           operator       = "StartsWith"
      #           selector       = ".MyCustom.Cookies" # .NET
      #         },
      #       }
      #     }
      #   }
      # }
    }
  }
  cdn_waf_custom_block_response_status_code = 503
  cdn_waf_custom_block_response_body        = "<h1>Service unavailable</h1>"

  ## Azure App Gateway specific configuration
  # app_gateway_v2_capacity_units               = 1
  # app_gateway_v2_frontend_port                = 443
  # app_gateway_v2_cookie_based_affinity        = "Disabled" # or "Enabled"
  # app_gateway_v2_tls_disabled_protocols       = ["TLSv1_0", "TLSv1_1"]
  # app_gateway_v2_identity_ids                 = []
  app_gateway_v2_waf_managed_rulesets           = {
    "OWASP" = {
      version = "3.2",
      # overrides = {
      #   "0000-RULE-GROUP-NAME-0000" = {
      #     rules = {
      #       "000001" = {
      #         enabled = false
      #       },
      #       "000002" = {
      #         enabled = true,
      #         action  = "Log"
      #       },
      #     }
      #   }
      # }
    },
    "Microsoft_BotManagerRuleSet" = {
      version = "1.0"
    }
  }
  # app_gateway_v2_waf_managed_rulesets_exclusions = {
  #   "rcn-sw-cookies" : {
  #     match_variable = "RequestCookieNames",
  #     selector = ".MyCustom.Cookies",
  #     selector_match_operator = "StartsWith"
  #     excluded_rule_set = {
  #       "OWASP" = {
  #         version         = "3.2",
  #         rule_group_name = "0000-RULE-GROUP-NAME-0000",
  #         excluded_rules  = [
  #           "12345",
  #           "67890"
  #         ]
  #       }
  #       "Microsoft_BotManagerRuleSet" = {
  #         version         = "1.0",
  #         rule_group_name = "1111-RULE-GROUP-NAME-1111",
  #         excluded_rules  = [
  #           "12345",
  #         ]
  #       }
  #     }
  #   },
  # }
  ## If your App Gateway is expected to sit behind Azure Front Door, then set this to True to only permit inbound traffic from that source
  # restrict_app_gateway_v2_to_front_door_inbound_only = true
  # restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefixes = [ "*" ]

  tags = {
    "Environment"      = "Dev"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 1.13 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.39 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 1.13 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 2.39 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_update_resource.container_app_storage_key_rotation_reminder](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) | resource |
| [azurerm_application_gateway.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) | resource |
| [azurerm_cdn_frontdoor_custom_domain.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain_association.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association) | resource |
| [azurerm_cdn_frontdoor_endpoint.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_firewall_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_firewall_policy) | resource |
| [azurerm_cdn_frontdoor_origin.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.add_origin_request_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.add_origin_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.remove_origin_request_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.remove_origin_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.remove_response_header](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.url_path_redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.global_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.origin_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.redirects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.url_path_redirects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_security_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_security_policy) | resource |
| [azurerm_key_vault.app_gateway_certificates](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_log_analytics_workspace.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_action_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_diagnostic_setting.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.app_gateway_v2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.cdn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.appgateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_monitor_scheduled_query_rules_alert_v2.frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource |
| [azurerm_network_security_group.app_gateway_v2_allow_frontdoor_inbound_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.app_gateway_v2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.app_gateway_certificates](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_route_table.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_storage_account.custom_error](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_blob.custom_error_web_pages](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_subnet.app_gateway_v2_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.app_gateway_v2_allow_frontdoor_inbound_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.app_gateway_v2_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_user_assigned_identity.app_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.source_to_origin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_web_application_firewall_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/web_application_firewall_policy) | resource |
| [azapi_resource_action.existing_logic_app_workflow_callback_url](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource_action) | data source |
| [azuread_user.key_vault_app_gateway_certificates_access](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_logic_app_workflow.existing_logic_app_workflow](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/logic_app_workflow) | data source |
| [azurerm_resource_group.existing_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_user_assigned_identity.app_gateway_v2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |
| [azurerm_virtual_network.existing_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_gateway_v2_capacity_units"></a> [app\_gateway\_v2\_capacity\_units](#input\_app\_gateway\_v2\_capacity\_units) | App Gateway V2 capacity units | `number` | `1` | no |
| <a name="input_app_gateway_v2_cookie_based_affinity"></a> [app\_gateway\_v2\_cookie\_based\_affinity](#input\_app\_gateway\_v2\_cookie\_based\_affinity) | App Gateway V2 Cookie Based Affinity. Sets an affinity cookie in the response with a hash value which contains the session details, so that the subsequent requests carrying the affinity cookie will be routed to the same backend server for maintaining stickiness. | `string` | `"Disabled"` | no |
| <a name="input_app_gateway_v2_custom_error_configuration"></a> [app\_gateway\_v2\_custom\_error\_configuration](#input\_app\_gateway\_v2\_custom\_error\_configuration) | A map of Status Codes to HTML URLs | `map(string)` | `{}` | no |
| <a name="input_app_gateway_v2_enable_http2"></a> [app\_gateway\_v2\_enable\_http2](#input\_app\_gateway\_v2\_enable\_http2) | App Gateway V2 enable HTTP2 | `bool` | `true` | no |
| <a name="input_app_gateway_v2_frontend_port"></a> [app\_gateway\_v2\_frontend\_port](#input\_app\_gateway\_v2\_frontend\_port) | App Gateway V2 frontend port | `number` | `80` | no |
| <a name="input_app_gateway_v2_identity_ids"></a> [app\_gateway\_v2\_identity\_ids](#input\_app\_gateway\_v2\_identity\_ids) | App Gateway V2 User Assigned identity ids. If empty, one will be created. | `list(any)` | `[]` | no |
| <a name="input_app_gateway_v2_waf_file_upload_limit_in_mb"></a> [app\_gateway\_v2\_waf\_file\_upload\_limit\_in\_mb](#input\_app\_gateway\_v2\_waf\_file\_upload\_limit\_in\_mb) | Maximum file size permitted in MB | `number` | `100` | no |
| <a name="input_app_gateway_v2_waf_managed_rulesets"></a> [app\_gateway\_v2\_waf\_managed\_rulesets](#input\_app\_gateway\_v2\_waf\_managed\_rulesets) | Map of all Managed rules you want to apply to the App Gateway WAF, including any overrides | <pre>map(object({<br/>    version : string,<br/>    overrides : optional(map(object({<br/>      rules : map(object({<br/>        enabled : bool,<br/>        action : optional(string, "Block")<br/>      }))<br/>    })), {})<br/>  }))</pre> | <pre>{<br/>  "Microsoft_BotManagerRuleSet": {<br/>    "version": "1.0"<br/>  },<br/>  "OWASP": {<br/>    "version": "3.2"<br/>  }<br/>}</pre> | no |
| <a name="input_app_gateway_v2_waf_managed_rulesets_exclusions"></a> [app\_gateway\_v2\_waf\_managed\_rulesets\_exclusions](#input\_app\_gateway\_v2\_waf\_managed\_rulesets\_exclusions) | Map of all exlusions and the assoicated Managed rules to apply to the App Gateway WAF | <pre>map(object({<br/>    match_variable : string,<br/>    selector : string,<br/>    selector_match_operator : string,<br/>    excluded_rule_set : map(object({<br/>      version : string,<br/>      rule_group_name : string,<br/>      excluded_rules : list(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_app_gateway_v2_waf_max_request_body_size_in_kb"></a> [app\_gateway\_v2\_waf\_max\_request\_body\_size\_in\_kb](#input\_app\_gateway\_v2\_waf\_max\_request\_body\_size\_in\_kb) | Maximum request size for a single request in KB. Has no effect if 'app\_gateway\_v2\_waf\_request\_body\_enforcement' is set to 'false' | `number` | `128` | no |
| <a name="input_app_gateway_v2_waf_request_body_enforcement"></a> [app\_gateway\_v2\_waf\_request\_body\_enforcement](#input\_app\_gateway\_v2\_waf\_request\_body\_enforcement) | Should the firewall block a request with a body size greater than 'app\_gateway\_v2\_waf\_max\_request\_body\_size\_in\_kb' | `bool` | `true` | no |
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location in which to launch resources. | `string` | n/a | yes |
| <a name="input_cdn_add_response_headers"></a> [cdn\_add\_response\_headers](#input\_cdn\_add\_response\_headers) | List of response headers to add at the CDN Front Door for all endpoints `[{ "Name" = "Strict-Transport-Security", "value" = "max-age=31536000" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_host_redirects"></a> [cdn\_host\_redirects](#input\_cdn\_host\_redirects) | CDN FrontDoor host redirects `[{ "from" = "example.com", "to" = "www.example.com" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_remove_response_headers"></a> [cdn\_remove\_response\_headers](#input\_cdn\_remove\_response\_headers) | List of response headers to remove at the CDN Front Door for all endpoints | `list(string)` | `[]` | no |
| <a name="input_cdn_sku"></a> [cdn\_sku](#input\_cdn\_sku) | Azure CDN Front Door SKU | `string` | `"Standard_AzureFrontDoor"` | no |
| <a name="input_cdn_url_path_redirects"></a> [cdn\_url\_path\_redirects](#input\_cdn\_url\_path\_redirects) | CDN FrontDoor url path redirects `[{ "redirect_type": "PermanentRedirect", "destination_path": "/example", "destination_hostname": "www.example.uk", "operator": "Equals", "match_values": ["/example"] }]` | <pre>list(object({<br/>    redirect_type        = string<br/>    redirect_protocol    = optional(string, null)<br/>    destination_path     = optional(string, null)<br/>    destination_hostname = optional(string, null)<br/>    destination_fragment = optional(string, null)<br/>    query_string         = optional(string, null)<br/>    operator             = string<br/>    match_values         = optional(list(string), [])<br/>    transforms           = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_cdn_waf_custom_block_response_body"></a> [cdn\_waf\_custom\_block\_response\_body](#input\_cdn\_waf\_custom\_block\_response\_body) | Base64 encoded custom response body when the WAF blocks a request | `string` | `""` | no |
| <a name="input_cdn_waf_custom_block_response_status_code"></a> [cdn\_waf\_custom\_block\_response\_status\_code](#input\_cdn\_waf\_custom\_block\_response\_status\_code) | Custom response status code when the WAF blocks a request. | `number` | `0` | no |
| <a name="input_cdn_waf_enable_rate_limiting"></a> [cdn\_waf\_enable\_rate\_limiting](#input\_cdn\_waf\_enable\_rate\_limiting) | Deploy a Rate Limiting Policy on the Front Door WAF | `bool` | `false` | no |
| <a name="input_cdn_waf_managed_rulesets"></a> [cdn\_waf\_managed\_rulesets](#input\_cdn\_waf\_managed\_rulesets) | Map of all Managed rules you want to apply to the CDN WAF, including any overrides, or exclusions | <pre>map(object({<br/>    version : string,<br/>    action : optional(string, "Block"),<br/>    exclusions : optional(map(object({<br/>      match_variable : string,<br/>      operator : string,<br/>      selector : string<br/>    })), {})<br/>    overrides : optional(map(map(object({<br/>      action : string,<br/>      enabled : optional(bool, true),<br/>      exclusions : optional(map(object({<br/>        match_variable : string,<br/>        operator : string,<br/>        selector : string<br/>      })), {})<br/>    }))), {})<br/>  }))</pre> | <pre>{<br/>  "BotProtection": {<br/>    "version": "preview-0.1"<br/>  },<br/>  "DefaultRuleSet": {<br/>    "version": "1.0"<br/>  }<br/>}</pre> | no |
| <a name="input_cdn_waf_rate_limiting_action"></a> [cdn\_waf\_rate\_limiting\_action](#input\_cdn\_waf\_rate\_limiting\_action) | Action to take when rate limiting (Block/Log) | `string` | `"Block"` | no |
| <a name="input_cdn_waf_rate_limiting_bypass_ip_list"></a> [cdn\_waf\_rate\_limiting\_bypass\_ip\_list](#input\_cdn\_waf\_rate\_limiting\_bypass\_ip\_list) | List if IP CIDRs to bypass the Rate Limit Policy | `list(string)` | `[]` | no |
| <a name="input_cdn_waf_rate_limiting_duration_in_minutes"></a> [cdn\_waf\_rate\_limiting\_duration\_in\_minutes](#input\_cdn\_waf\_rate\_limiting\_duration\_in\_minutes) | Number of minutes to BLOCK requests that hit the Rate Limit threshold | `number` | `1` | no |
| <a name="input_cdn_waf_rate_limiting_threshold"></a> [cdn\_waf\_rate\_limiting\_threshold](#input\_cdn\_waf\_rate\_limiting\_threshold) | Maximum number of concurrent requests before Rate Limiting policy is applied | `number` | `300` | no |
| <a name="input_enable_key_vault_app_gateway_certificates"></a> [enable\_key\_vault\_app\_gateway\_certificates](#input\_enable\_key\_vault\_app\_gateway\_certificates) | Deploy a Key Vault to hold TLS Certificates for use by App Gateway | `bool` | `true` | no |
| <a name="input_enable_latency_monitor"></a> [enable\_latency\_monitor](#input\_enable\_latency\_monitor) | Enable CDN latency monitor | `bool` | `false` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Enable WAF | `bool` | `false` | no |
| <a name="input_enable_waf_alert"></a> [enable\_waf\_alert](#input\_enable\_waf\_alert) | Toggle to enable or disable the WAF logs alert | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_existing_logic_app_workflow"></a> [existing\_logic\_app\_workflow](#input\_existing\_logic\_app\_workflow) | Name, Resource Group and HTTP Trigger URL of an existing Logic App Workflow | <pre>object({<br/>    name : string<br/>    resource_group_name : string<br/>  })</pre> | <pre>{<br/>  "name": "",<br/>  "resource_group_name": ""<br/>}</pre> | no |
| <a name="input_existing_monitor_action_group_id"></a> [existing\_monitor\_action\_group\_id](#input\_existing\_monitor\_action\_group\_id) | ID of an existing monitor action group | `string` | `""` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Conditionally launch resources into an existing resource group. Specifying this will NOT create a resource group. | `string` | `""` | no |
| <a name="input_existing_virtual_network"></a> [existing\_virtual\_network](#input\_existing\_virtual\_network) | Conditionally use an existing virtual network. The `virtual_network_address_space` must match an existing address space in the VNet. This also requires the resource group name. | `string` | `""` | no |
| <a name="input_key_vault_app_gateway_certificates_access_ipv4"></a> [key\_vault\_app\_gateway\_certificates\_access\_ipv4](#input\_key\_vault\_app\_gateway\_certificates\_access\_ipv4) | List of IPv4 Addresses that are permitted to access the App Gateway Certificates Key Vault | `list(string)` | `[]` | no |
| <a name="input_key_vault_app_gateway_certificates_access_subnet_ids"></a> [key\_vault\_app\_gateway\_certificates\_access\_subnet\_ids](#input\_key\_vault\_app\_gateway\_certificates\_access\_subnet\_ids) | List of Azure Subnet IDs that are permitted to access the App Gateway Certificates Key Vault | `list(string)` | `[]` | no |
| <a name="input_key_vault_app_gateway_certificates_access_users"></a> [key\_vault\_app\_gateway\_certificates\_access\_users](#input\_key\_vault\_app\_gateway\_certificates\_access\_users) | List of users that require access to the App Gateway Certificates Key Vault. This should be a list of User Principle Names (Found in Active Directory) that need to run terraform | `list(string)` | `[]` | no |
| <a name="input_key_vault_app_gateway_enable_rbac"></a> [key\_vault\_app\_gateway\_enable\_rbac](#input\_key\_vault\_app\_gateway\_enable\_rbac) | Use RBAC authorisation on the App Gateway Certificates Key Vault. Has no effect if key\_vault\_app\_gateway\_certificates\_access\_users is defined. | `bool` | `false` | no |
| <a name="input_latency_monitor_threshold"></a> [latency\_monitor\_threshold](#input\_latency\_monitor\_threshold) | CDN latency monitor threshold in milliseconds | `number` | `5000` | no |
| <a name="input_monitor_email_receivers"></a> [monitor\_email\_receivers](#input\_monitor\_email\_receivers) | A list of email addresses that should be notified by monitoring alerts | `list(string)` | `[]` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_response_request_timeout"></a> [response\_request\_timeout](#input\_response\_request\_timeout) | Azure CDN Front Door response timeout, or app gateway v2 request timeout in seconds | `number` | `120` | no |
| <a name="input_restrict_app_gateway_v2_to_front_door_inbound_only"></a> [restrict\_app\_gateway\_v2\_to\_front\_door\_inbound\_only](#input\_restrict\_app\_gateway\_v2\_to\_front\_door\_inbound\_only) | Restricts access to the App Gateway V2 by creating a network security group that only allows 'AzureFrontDoor.Backend' inbound, and attaches it to the subnet of the application gateway. | `bool` | `false` | no |
| <a name="input_restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefix"></a> [restrict\_app\_gateway\_v2\_to\_front\_door\_inbound\_only\_destination\_prefix](#input\_restrict\_app\_gateway\_v2\_to\_front\_door\_inbound\_only\_destination\_prefix) | If app gateway v2 has access restricted to front door only (by enabling `restrict_app_gateway_v2_to_front_door_inbound_only`), use this to set the destination prefix for the security group rule. | `string` | `"*"` | no |
| <a name="input_restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefixes"></a> [restrict\_app\_gateway\_v2\_to\_front\_door\_inbound\_only\_destination\_prefixes](#input\_restrict\_app\_gateway\_v2\_to\_front\_door\_inbound\_only\_destination\_prefixes) | If app gateway v2 has access restricted to front door only (by enabling `restrict_app_gateway_v2_to_front_door_inbound_only`), use this to set the destination prefixes for the security group rule. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | Virtual Network address space CIDR | `string` | `"172.16.0.0/12"` | no |
| <a name="input_waf_application"></a> [waf\_application](#input\_waf\_application) | Which product to apply the WAF to. Must be either CDN or AppGatewayV2 | `string` | `"CDN"` | no |
| <a name="input_waf_custom_rules"></a> [waf\_custom\_rules](#input\_waf\_custom\_rules) | Map of all Custom rules you want to apply to the WAF | <pre>map(object({<br/>    priority : number,<br/>    action : string<br/>    match_conditions : map(object({<br/>      match_variable : string,<br/>      match_values : optional(list(string), []),<br/>      operator : optional(string, "Any"),<br/>      selector : optional(string, null),<br/>      negation_condition : optional(bool, false),<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | WAF mode | `string` | `"Prevention"` | no |
| <a name="input_waf_targets"></a> [waf\_targets](#input\_waf\_targets) | Target endpoints to configure the WAF to point towards | <pre>map(<br/>    object({<br/>      domain : string,<br/>      cdn_create_custom_domain : optional(bool, false),<br/>      custom_fqdn : optional(string, "")<br/>      app_gateway_v2_ssl_certificate_key_vault_id : optional(string, "")<br/>      app_gateway_v2_use_private_listener : optional(string, false)<br/>      vnet_peering_target : optional(object({<br/>        name : string,<br/>        resource_group_name : string<br/>      }))<br/>      enable_health_probe : optional(bool, true),<br/>      health_probe_interval : optional(number, 60),<br/>      health_probe_request_type : optional(string, "HEAD"),<br/>      health_probe_path : optional(string, "/"),<br/>      cdn_add_response_headers : optional(list(object({<br/>        name : string,<br/>        value : string<br/>        })<br/>      ), [])<br/>      cdn_add_request_headers : optional(list(object({<br/>        name : string,<br/>        value : string<br/>        })<br/>      ), [])<br/>      cdn_remove_response_headers : optional(list(string), [])<br/>      cdn_remove_request_headers : optional(list(string), [])<br/>      custom_errors : optional(object({<br/>        error_page_directory : string,<br/>        error_pages : map(string)<br/>      }), null)<br/>    })<br/>  )</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_error_web_page_storage_accounts"></a> [custom\_error\_web\_page\_storage\_accounts](#output\_custom\_error\_web\_page\_storage\_accounts) | Storage Accounts used for holding custom error pages |
| <a name="output_environment"></a> [environment](#output\_environment) | n/a |
<!-- END_TF_DOCS -->
