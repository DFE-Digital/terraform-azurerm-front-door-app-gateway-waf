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
