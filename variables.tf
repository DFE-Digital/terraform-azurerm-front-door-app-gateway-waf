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

variable "enable_health_probe" {
  description = "Enable CDN Front Door health probe"
  type        = bool
  default     = true
}

variable "enable_latency_monitor" {
  description = "Monitor latency between the Front Door and it's origin"
  type        = bool
  default     = true
}

variable "monitor_action_group_id" {
  description = "Specify the Action Group ID that you want to send the Latency monitor alerts to"
  type        = string
}

variable "alarm_latency_threshold_ms" {
  description = "Specify a number in milliseconds which should be set as a threshold for a request latency monitoring alarm"
  type        = number
  default     = 1000
}

variable "health_probe_interval" {
  description = "Specifies the number of seconds between health probes."
  type        = number
  default     = 120
}

variable "health_probe_path" {
  description = "Specifies the path relative to the origin that is used to determine the health of the origin."
  type        = string
  default     = "/"
}

variable "health_probe_request_type" {
  description = "Specifies the type of health probe request that is made."
  type        = string
  default     = "GET"
}

variable "response_timeout" {
  description = "Azure CDN Front Door response timeout in seconds"
  type        = number
  default     = 120
}

variable "origins" {
  description = "A list of origin host names keyed by an identifier"
  type        = map(any)
  default     = {}
}

variable "custom_domains" {
  description = "Azure CDN Front Door custom domains. If they are within the DNS zone (optionally created), the Validation TXT records and ALIAS/CNAME records will be created"
  type        = map(any)
  default     = {}
}

variable "https_redirect_enabled" {
  description = "Redirect all HTTP traffic to HTTPS"
  type        = bool
  default     = true
}

variable "use_existing_key_vault" {
  description = "Use an existing Key Vault to store a Customer managed Certificate"
  type        = bool
  default     = false
}

variable "existing_key_vault_id" {
  description = "The ID of an existing Key Vault. Must be defined if 'use_existing_key_vault' is true"
  type        = string
  default     = ""
}

variable "key_vault_allow_ipv4_list" {
  description = "A list of IPv4 addresses to permit access to the Key Vault that holds the TLS Certificates"
  type        = list(string)
  default     = []
}

variable "azuread_application_display_name" {
  description = "The name of an Azure AD App Registration that can access Key Vault and Azure Front Door"
  type        = string
  default     = "Microsoft.AzureFrontDoor-Cdn"
}

variable "certificates" {
  description = "Customer managed certificates (.pfx)"
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

variable "waf_enable_bot_protection" {
  description = "Deploy a Bot Protection Policy on the Front Door WAF"
  type        = bool
  default     = false
}

variable "waf_use_preview_bot_ruleset" {
  description = "Use the newer 'BotProtection' ruleset instead of the older 'Microsoft_BotManagerRuleSet' ruleset"
  type        = bool
  default     = true
}

variable "waf_enable_default_ruleset" {
  description = "Deploy a Managed DRS Policy on the Front Door WAF"
  type        = bool
  default     = false
}

variable "waf_use_new_default_ruleset" {
  description = "Use the newer 'DefaultRuleSet' ruleset instead of the older 'Microsoft_DefaultRuleSet' ruleset"
  type        = bool
  default     = true
}
