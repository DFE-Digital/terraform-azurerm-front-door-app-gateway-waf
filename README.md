# Azure Front Door WAF terraform module

[![Terraform CI](./actions/workflows/continuous-integration-terraform.yml/badge.svg?branch=main)](./actions/workflows/continuous-integration-terraform.yml?branch=main)
[![GitHub release](./releases)](./releases)

This module creates and manages an Azure Front Door, and Front Door WAF.

## Usage

Example module usage:

```hcl
module "azurerm_front_door_waf" {
  source  = "github.com/dfe-digital/terraform-azuerm-front-door-waf?ref=v0.1.0"

  environment    = "dev"
  project_name   = "frontdoorwaf"
  azure_location = "uksouth"

  cdn_sku                     = "Premium_AzureFrontDoor" # or "Standard_AzureFrontDoor"
  cdn_response_timeout        = 60 # seconds

  endpoints = {
    "example" = {
      domain                    = "example.com",
      create_custom_domain      = false
      enable_health_probe       = true
      health_probe_interval     = 60
      health_probe_request_type = "HEAD"
      health_probe_path         = "/"
    },
    "example2" = {
      domain                    = "example2.com"
      create_custom_domain      = true
      enable_health_probe       = true
      health_probe_interval     = 60
      health_probe_request_type = "GET"
      health_probe_path         = "/healthcheck"
    },
  }

  tags = {
    "Environment"      = "Dev"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.51.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.51.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_cdn_frontdoor_custom_domain.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain_association.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association) | resource |
| [azurerm_cdn_frontdoor_endpoint.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_origin.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.waf](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.remove_response_header](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.add_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.redirects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_rule_set.remove_response_headers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_monitor_metric_alert.cdn_latency](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group.existing_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location in which to launch resources. | `string` | n/a | yes |
| <a name="input_cdn_host_add_response_headers"></a> [cdn\_host\_add\_response\_headers](#input\_cdn\_host\_add\_response\_headers) | List of response headers to add at the CDN Front Door `[{ "Name" = "Strict-Transport-Security", "value" = "max-age=31536000" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_host_redirects"></a> [cdn\_host\_redirects](#input\_cdn\_host\_redirects) | CDN FrontDoor host redirects `[{ "from" = "example.com", "to" = "www.example.com" }]` | `list(map(string))` | `[]` | no |
| <a name="input_cdn_latency_monitor_threshold"></a> [cdn\_latency\_monitor\_threshold](#input\_cdn\_latency\_monitor\_threshold) | CDN latency monitor threshold in milliseconds | `number` | `5000` | no |
| <a name="input_cdn_remove_response_headers"></a> [cdn\_remove\_response\_headers](#input\_cdn\_remove\_response\_headers) | List of response headers to remove at the CDN Front Door | `list(string)` | `[]` | no |
| <a name="input_cdn_response_timeout"></a> [cdn\_response\_timeout](#input\_cdn\_response\_timeout) | Azure CDN Front Door response timeout in seconds | `number` | `120` | no |
| <a name="input_cdn_sku"></a> [cdn\_sku](#input\_cdn\_sku) | Azure CDN Front Door SKU | `string` | `"Standard_AzureFrontDoor"` | no |
| <a name="input_cdn_waf_targets"></a> [cdn\_waf\_targets](#input\_cdn\_waf\_targets) | Target endpoints to configure the WAF to point towards | <pre>map(<br>    object({<br>      domain : string,<br>      create_custom_domain : optional(bool, false),<br>      enable_health_probe : optional(bool, true),<br>      health_probe_interval : optional(number, 60),<br>      health_probe_request_type : optional(string, "HEAD"),<br>      health_probe_path : optional(string, "/")<br>    })<br>  )</pre> | `{}` | no |
| <a name="input_enable_cdn_latency_monitor"></a> [enable\_cdn\_latency\_monitor](#input\_enable\_cdn\_latency\_monitor) | Enable CDN latency monitor | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. Will be used along with `project_name` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_existing_monitor_action_group_id"></a> [existing\_monitor\_action\_group\_id](#input\_existing\_monitor\_action\_group\_id) | ID of an existing monitor action group | `string` | `""` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Conditionally launch resources into an existing resource group. Specifying this will NOT create a resource group. | `string` | `""` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. Will be used along with `environment` as a prefix for all resources. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment"></a> [environment](#output\_environment) | n/a |
<!-- END_TF_DOCS -->
