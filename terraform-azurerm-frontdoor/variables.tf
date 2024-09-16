variable "resource_group_name" {
  description = "Target resource where the component is going to be deployed"
  type        = string
}

variable "location" {
  description = "Location of the resource"
  type        = string
  default     = "eastus"
}

variable "frontdoor_profile" {
  description = "The profile configuration. Standard Sku is default."
  type = object({
    name     = string
    sku_name = optional(string, "Standard_AzureFrontDoor")
    tags     = optional(object({}), null)
  })
}

variable "origin_groups" {
  description = "List of origin groups."
  type = map(object({
    session_affinity_enabled = optional(bool)
    restore_traffic_time     = optional(number)
    health_probe = optional(object({
      interval_in_seconds = optional(number)
      path                = optional(string)
      protocol            = optional(string)
      request_type        = optional(string)
    }))
    load_balancing = optional(object({
      latency_in_milliseconds = optional(number)
      sample_size             = optional(number)
      sample_required         = optional(number)
    }))
  }))
}

variable "origin_list" {
  type = map(object({
    origin_group_name              = string
    enabled                        = optional(bool, true)
    certificate_name_check_enabled = optional(bool, false)
    host_name                      = string
    http_port                      = optional(number, 80)
    https_port                     = optional(number, 443)
    origin_host_header             = optional(string)
    priority                       = optional(number, 1)
    weight                         = optional(number, 1)
  }))
}

variable "custom_domains" {
  type    = list(any)
  default = []
}

variable "dns_zones" {
  type    = list(string)
  default = []
}

variable "routes" {
  type = map(any)
  default = {
  }
}

variable "endpoints" {
  type = list(string)
}

variable "rule_sets" {
  type = map(any)
  default = {

  }
}