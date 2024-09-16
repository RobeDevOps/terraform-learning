module "frontdoor" {
  source              = "../.."
  resource_group_name = var.resource_group_name
  frontdoor_profile   = var.frontdoor_profile
  origin_groups       = var.origin_groups
  origin_list         = var.origin_list
  dns_zones           = var.dns_zones
  custom_domains      = var.custom_domains
  routes              = var.routes
  endpoints           = var.endpoints
  rule_sets           = var.rule_sets
}

