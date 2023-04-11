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

variable "sku" {
  description = "Azure CDN Front Door SKU"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "enable_latency_monitor" {
  description = "Monitor latency between the Front Door and it's origin"
  type        = bool
  default     = true
}

variable "monitor_action_group_id" {
  description = "Specify the Action Group ID that you want to send the Latency monitor alerts to. Required if 'enable_latency_monitor' is true"
  type        = string
}

variable "alarm_latency_threshold_ms" {
  description = "Specify a number in milliseconds which should be set as a threshold for a request latency monitoring alarm"
  type        = number
  default     = 1000
}

variable "response_timeout" {
  description = "Azure CDN Front Door response timeout in seconds"
  type        = number
  default     = 120
}

variable "endpoints" {
  description = ""
  type        = map(any)
  default     = {}
}

variable "host_redirects" {
  description = "CDN FrontDoor host redirects `[{ \"from\" = \"example.com\", \"to\" = \"www.example.com\" }]`"
  type        = list(map(string))
  default     = []
}

variable "host_add_response_headers" {
  description = "List of response headers to add at the CDN Front Door `[{ \"Name\" = \"Strict-Transport-Security\", \"value\" = \"max-age=31536000\" }]`"
  type        = list(map(string))
  default     = []
}

variable "remove_response_headers" {
  description = "List of response headers to remove at the CDN Front Door"
  type        = list(string)
  default     = []
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

variable "waf_managed_rulesets" {
  description = "Map of all Managed rules you want to apply to the WAF, including any overrides"
  type        = map(any)
  default = {
    "BotProtection" : {
      version : "preview-0.1",
      action : "Block"
    },
    "DefaultRuleSet" : {
      version : "1.0",
      action : "Block"
    }
  }
}

variable "waf_custom_rules" {
  description = "Map of all Custom rules you want to apply to the WAF"
  type        = map(any)
  default     = {}
}
