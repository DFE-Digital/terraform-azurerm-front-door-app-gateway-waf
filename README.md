# <REPLACE WITH USEFUL TERRAFORM DESCRIPTION>

[![Terraform CI](./actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](./actions/workflows/continuous-integration-terraform.yml?branch=main)
[![GitHub release](./releases)](./releases)

This module creates and manages an Azure Front Door, and Front Door WAF. If you want to use your own TLS Certificates, it can also create and manage a Key Vault, or you can use an existing one.

## Usage

Example module usage:

```hcl
module "azurerm_front_door_waf" {
  source  = "github.com/dfe-digital/terraform-azuerm-front-door-waf?ref=v0.1.0"

  environment    = "dev"
  project_name   = "frontdoor"
  azure_location = "uksouth"

  sku                     = "Premium_AzureFrontDoor" # or "Standard_AzureFrontDoor"
  response_timeout        = 60 # seconds
  enable_latency_monitor  = true
  ## Action Group ID
  # monitor_action_group_id = "/xxx/abcdefg"

  origin_groups = {
    "first-origin-group" = {
      origins = [
        "my-origin.hostname"
      ],
      domains                   = [
        "my-custom.domain.tld
      ]
      enable_health_probe       = true
      health_probe_interval     = 60
      health_probe_request_type = "HEAD"
      health_probe_path         = "/"
    },
    "second-origin-group" = {
      origins = [
        "second-origin.hostname"
      ],
      domains                   = [
        "second-custom.domain.tld
      ]
      enable_health_probe       = true
      health_probe_interval     = 60
      health_probe_request_type = "GET"
      health_probe_path         = "/healthcheck"
    },
  }

  certificates = {
    "certificate0": {
      password : "xyz,
      contents : filebase64(abspath("/path/to/file.pfx"))
    }
  }

  key_vault_access_users = [
    "my.email_domain.tld#EXT#@platformidentity.onmicrosoft.com",
  ]

  key_vault_allow_ipv4_list = [
    "8.8.8.8", # Replace with a trusted IP range
  ]

  enable_waf                            = true
  waf_enable_rate_limiting              = true
  waf_rate_limiting_duration_in_minutes = 5
  waf_rate_limiting_threshold           = 1000
  waf_rate_limiting_bypass_ip_list      = []
  waf_enable_bot_protection             = true
  waf_enable_default_ruleset            = true

  tags = {
    "Environment"      = "Dev"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.2 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 1.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.36.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.47.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 1.4.0 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.36.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.49.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_update_resource.frontdoor_system_identity](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) | resource |
| [azurerm_cdn_frontdoor_custom_domain.custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain_association.custom_domain_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association) | resource |
| [azurerm_cdn_frontdoor_endpoint.endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_firewall_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_firewall_policy) | resource |
| [azurerm_cdn_frontdoor_origin.origin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.cdn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.remove_response_header](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.redirects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.remove_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_secret.frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_secret) | resource |
| [azurerm_cdn_frontdoor_security_policy.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_security_policy) | resource |
| [azurerm_key_vault.frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_certificate.frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_certificate) | resource |
| [azurerm_monitor_metric_alert.latency](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azuread_user.key_vault_access](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.existing_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_latency_threshold_ms"></a> [alarm\_latency\_threshold\_ms](#input\_alarm\_latency\_threshold\_ms) | Specify a number in milliseconds which should be set as a threshold for a request latency monitoring alarm | `number` | `1000` | no |
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location in which to launch resources. | `string` | n/a | yes |
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Customer managed certificates (.pfx) | `map(any)` | `{}` | no |
| <a name="input_enable_latency_monitor"></a> [enable\_latency\_monitor](#input\_enable\_latency\_monitor) | Monitor latency between the Front Door and it's origin | `bool` | `true` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Enable CDN Front Door WAF | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_existing_key_vault_id"></a> [existing\_key\_vault\_id](#input\_existing\_key\_vault\_id) | The ID of an existing Key Vault. Must be defined if 'use\_existing\_key\_vault' is true | `string` | `""` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Conditionally launch resources into an existing resource group. Specifying this will NOT create a resource group. | `string` | `""` | no |
| <a name="input_host_add_response_headers"></a> [host\_add\_response\_headers](#input\_host\_add\_response\_headers) | List of response headers to add at the CDN Front Door `[{ "Name" = "Strict-Transport-Security", "value" = "max-age=31536000" }]` | `list(map(string))` | `[]` | no |
| <a name="input_host_redirects"></a> [host\_redirects](#input\_host\_redirects) | CDN FrontDoor host redirects `[{ "from" = "example.com", "to" = "www.example.com" }]` | `list(map(string))` | `[]` | no |
| <a name="input_key_vault_access_users"></a> [key\_vault\_access\_users](#input\_key\_vault\_access\_users) | A list of Azure AD Users that are granted Secret & Certificate management permissions to the Key Vault | `list(string)` | `[]` | no |
| <a name="input_key_vault_allow_ipv4_list"></a> [key\_vault\_allow\_ipv4\_list](#input\_key\_vault\_allow\_ipv4\_list) | A list of IPv4 addresses to permit access to the Key Vault that holds the TLS Certificates | `list(string)` | `[]` | no |
| <a name="input_monitor_action_group_id"></a> [monitor\_action\_group\_id](#input\_monitor\_action\_group\_id) | Specify the Action Group ID that you want to send the Latency monitor alerts to. Required if 'enable\_latency\_monitor' is true | `string` | n/a | yes |
| <a name="input_origin_groups"></a> [origin\_groups](#input\_origin\_groups) | n/a | `map(any)` | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_remove_response_headers"></a> [remove\_response\_headers](#input\_remove\_response\_headers) | List of response headers to remove at the CDN Front Door | `list(string)` | `[]` | no |
| <a name="input_response_timeout"></a> [response\_timeout](#input\_response\_timeout) | Azure CDN Front Door response timeout in seconds | `number` | `120` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | Azure CDN Front Door SKU | `string` | `"Standard_AzureFrontDoor"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to all resources | `map(string)` | `{}` | no |
| <a name="input_use_existing_key_vault"></a> [use\_existing\_key\_vault](#input\_use\_existing\_key\_vault) | Use an existing Key Vault to store a Customer managed Certificate | `bool` | `false` | no |
| <a name="input_waf_enable_bot_protection"></a> [waf\_enable\_bot\_protection](#input\_waf\_enable\_bot\_protection) | Deploy a Bot Protection Policy on the Front Door WAF | `bool` | `false` | no |
| <a name="input_waf_enable_default_ruleset"></a> [waf\_enable\_default\_ruleset](#input\_waf\_enable\_default\_ruleset) | Deploy a Managed DRS Policy on the Front Door WAF | `bool` | `false` | no |
| <a name="input_waf_enable_rate_limiting"></a> [waf\_enable\_rate\_limiting](#input\_waf\_enable\_rate\_limiting) | Deploy a Rate Limiting Policy on the Front Door WAF | `bool` | `false` | no |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | CDN Front Door WAF mode | `string` | `"Prevention"` | no |
| <a name="input_waf_rate_limiting_bypass_ip_list"></a> [waf\_rate\_limiting\_bypass\_ip\_list](#input\_waf\_rate\_limiting\_bypass\_ip\_list) | List if IP CIDRs to bypass the Rate Limit Policy | `list(string)` | `[]` | no |
| <a name="input_waf_rate_limiting_duration_in_minutes"></a> [waf\_rate\_limiting\_duration\_in\_minutes](#input\_waf\_rate\_limiting\_duration\_in\_minutes) | Number of minutes to BLOCK requests that hit the Rate Limit threshold | `number` | `1` | no |
| <a name="input_waf_rate_limiting_threshold"></a> [waf\_rate\_limiting\_threshold](#input\_waf\_rate\_limiting\_threshold) | Maximum number of concurrent requests before Rate Limiting policy is applied | `number` | `300` | no |
| <a name="input_waf_use_new_default_ruleset"></a> [waf\_use\_new\_default\_ruleset](#input\_waf\_use\_new\_default\_ruleset) | Use the newer 'DefaultRuleSet' ruleset instead of the older 'Microsoft\_DefaultRuleSet' ruleset | `bool` | `true` | no |
| <a name="input_waf_use_preview_bot_ruleset"></a> [waf\_use\_preview\_bot\_ruleset](#input\_waf\_use\_preview\_bot\_ruleset) | Use the newer 'BotProtection' ruleset instead of the older 'Microsoft\_BotManagerRuleSet' ruleset | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azurerm_resource_group_default"></a> [azurerm\_resource\_group\_default](#output\_azurerm\_resource\_group\_default) | Default Azure Resource Group |
| <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains) | List of all Custom Domain associations |
| <a name="output_environment"></a> [environment](#output\_environment) | n/a |
| <a name="output_origin_groups"></a> [origin\_groups](#output\_origin\_groups) | List of all Origin Groups |
| <a name="output_origins"></a> [origins](#output\_origins) | List of all Origins |
| <a name="output_routes"></a> [routes](#output\_routes) | List of all Routes |
<!-- END_TF_DOCS -->
