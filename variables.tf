variable "environment" {
  description = "Environment name. Will be used along with `project_name` as a prefix for all resources."
  type        = string
}

variable "project_name" {
  description = "Project name. Will be used along with `environment` as a prefix for all resources."
  type        = string
}

variable "azure_location" {
  description = "Azure location in which to launch resources."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "existing_resource_group" {
  description = "Conditionally launch resources into an existing resource group. Specifying this will NOT create a resource group."
  type        = string
  default     = ""
}

variable "cdn_sku" {
  description = "Azure CDN Front Door SKU"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "cdn_response_timeout" {
  description = "Azure CDN Front Door response timeout in seconds"
  type        = number
  default     = 120
}

variable "cdn_waf_targets" {
  description = "Target endpoints to configure the WAF to point towards"
  type = map(
    object({
      domain : string,
      create_custom_domain : optional(bool, false),
      enable_health_probe : optional(bool, true),
      health_probe_interval : optional(number, 60),
      health_probe_request_type : optional(string, "HEAD"),
      health_probe_path : optional(string, "/")
    })
  )
  default = {}
}

variable "cdn_host_redirects" {
  description = "CDN FrontDoor host redirects `[{ \"from\" = \"example.com\", \"to\" = \"www.example.com\" }]`"
  type        = list(map(string))
  default     = []
}

variable "cdn_host_add_response_headers" {
  description = "List of response headers to add at the CDN Front Door `[{ \"Name\" = \"Strict-Transport-Security\", \"value\" = \"max-age=31536000\" }]`"
  type        = list(map(string))
  default     = []
}

variable "cdn_remove_response_headers" {
  description = "List of response headers to remove at the CDN Front Door"
  type        = list(string)
  default     = []
}

variable "existing_monitor_action_group_id" {
  description = "ID of an existing monitor action group"
  type        = string
  default     = ""
}

variable "enable_cdn_latency_monitor" {
  description = "Enable CDN latency monitor"
  type        = bool
  default     = false
}

variable "cdn_latency_monitor_threshold" {
  description = "CDN latency monitor threshold in milliseconds"
  type        = number
  default     = 5000
}

variable "enable_waf" {
  description = "Enable CDN Front Door WAF"
  type        = bool
  default     = false
}

variable "waf_mode" {
  description = "CDN Front Door WAF mode"
  type        = string
  default     = "Prevention"
}

variable "waf_enable_rate_limiting" {
  description = "Deploy a Rate Limiting Policy on the Front Door WAF"
  type        = bool
  default     = false
}

variable "waf_rate_limiting_duration_in_minutes" {
  description = "Number of minutes to BLOCK requests that hit the Rate Limit threshold"
  type        = number
  default     = 1
}

variable "waf_rate_limiting_threshold" {
  description = "Maximum number of concurrent requests before Rate Limiting policy is applied"
  type        = number
  default     = 300
}

variable "waf_rate_limiting_bypass_ip_list" {
  description = "List if IP CIDRs to bypass the Rate Limit Policy"
  type        = list(string)
  default     = []
}

variable "waf_rate_limiting_action" {
  description = "Action to take when rate limiting (Block/Log)"
  type        = string
  default     = "Block"
}

variable "waf_managed_rulesets" {
  description = "Map of all Managed rules you want to apply to the WAF, including any overrides"
  type = map(object({
    version : string,
    action : string,
    exclusions : optional(map(object({
      match_variable : string,
      operator : string,
      selector : string
    })), {})
    overrides : optional(map(map(object({
      action : string,
      exclusions : optional(map(object({
        match_variable : string,
        operator : string,
        selector : string
      })), {})
    }))), {})
  }))
  default = {}
}

variable "waf_custom_rules" {
  description = "Map of all Custom rules you want to apply to the WAF"
  type = map(object({
    priority : number,
    action : string,
    match_conditions : map(object({
      match_variable : string,
      match_values : list(string),
      operator : string,
      selector : optional(string, null)
    }))
  }))
  default = {}
}

variable "waf_custom_block_response_status_code" {
  description = "Custom response status code when the WAF blocks a request."
  type        = number
  default     = 0
}

variable "waf_custom_block_response_body" {
  description = "Base64 encoded custom response body when the WAF blocks a request"
  type        = string
  default     = ""
}
